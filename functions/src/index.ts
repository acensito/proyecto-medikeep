// CLoud Functions de MediKeep
// Importamos las "herramientas" de Firebase para el backend
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Inicializamos la "llave maestra" de administrador
admin.initializeApp();
const db = admin.firestore();

// --- GESTIÓN DE BORRADO EN CASCADA (TRIGGERS DE EVENTOS) ---

// TAREA 1: Borrado en cascada de SPACE
export const onSpaceDeleted = functions.firestore
  .document("spaces/{spaceId}")
  .onDelete(async (snap, context) => {
    const spaceId = context.params.spaceId;
    console.log(`* Iniciando demolición del Space: ${spaceId}`);

    const storageBoxRef = db.collection("spaces").doc(spaceId)
      .collection("storage_boxes");
    await deleteCollection(storageBoxRef);

    const medicationsRef = db.collection("spaces").doc(spaceId)
      .collection("medications");
    await deleteCollection(medicationsRef);

    // Limpiar las "llaves" de los Usuarios
    const usersQuery = db.collection("users")
      .where("spaceIds", "array-contains", spaceId);
    const usersSnapshot = await usersQuery.get();
    const batch = db.batch();
    usersSnapshot.forEach((doc) => {
      console.log(`Actualizando al usuario ${doc.id}, quitando el Space ${spaceId}`);
      batch.update(doc.ref, {
        spaceIds: admin.firestore.FieldValue.arrayRemove(spaceId),
      });
    });
    await batch.commit();

    console.log(`* Demolición del Space ${spaceId} completada`);
    return null;
  });


// TAREA 2: Borrado en cascada de STORAGEBOX
export const onStorageBoxDeleted = functions.firestore
  .document("spaces/{spaceId}/storage_boxes/{storageBoxId}")
  .onDelete(async (snap, context) => {
    const spaceId = context.params.spaceId;
    const storageBoxId = context.params.storageBoxId;
    console.log(`* Demoliendo medicamentos del StorageBox: ${storageBoxId}`);

    const medicationsQuery = db.collection("spaces").doc(spaceId)
      .collection("medications")
      .where("storageBoxId", "==", storageBoxId);

    const medicationsSnapshot = await medicationsQuery.get();

    if (medicationsSnapshot.empty) {
      console.log("No se encontraron medicamentos para demoler.");
      return null;
    }

    const batch = db.batch();
    medicationsSnapshot.forEach((doc) => {
      console.log(`Borrando medicamento huérfano: ${doc.id}`);
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`* Demolición de medicamentos del StorageBox ${storageBoxId} completada`);
    return null;
  });


// --- GESTIÓN DE MIEMBROS (LLAMADAS HTTPS) ---

// Invitación de miembro
export const inviteMemberToSpace = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    const spaceId = data.spaceId;
    const invitedEmail = data.invitedEmail;
    const role = data.role; 

    // ... (Validaciones de seguridad iniciales) ...
    if (!callerUid || !spaceId || !invitedEmail || !role) {
        throw new functions.https.HttpsError("invalid-argument", "Faltan parámetros.");
    }
    
    const batch = db.batch();

    try {
        // BUSCAR AL USUARIO INVITADO POR EMAIL (Necesario para el ID)
        const userQuery = db.collection("users").where("email", "==", invitedEmail).limit(1);
        const userSnapshot = await userQuery.get();

        if (userSnapshot.empty) {
            throw new functions.https.HttpsError("not-found", "No se encontró un usuario registrado con ese email.");
        }

        const invitedUserDoc = userSnapshot.docs[0];
        const invitedUid = invitedUserDoc.id; 

        // VERIFICACIÓN DE OWNER y EXISTENCIA (La CF lo hace por seguridad)
        const spaceRef = db.collection("spaces").doc(spaceId);
        const spaceDoc = await spaceRef.get();
        if (!spaceDoc.exists) throw new functions.https.HttpsError("not-found", "El Space no existe.");

        const members = spaceDoc.data()?.members || {};
        if (members[callerUid] !== "owner") {
            throw new functions.https.HttpsError("permission-denied", "Solo el propietario puede invitar miembros.");
        }
        if (members[invitedUid]) {
             throw new functions.https.HttpsError("already-exists", "Este usuario ya es miembro del Space.");
        }

        // OPERACIÓN A: Añadir el miembro al Space
        batch.update(spaceRef, { [`members.${invitedUid}`]: role });

        // OPERACIÓN B: Actualizar el perfil del usuario invitado (spaceIds array)
        const invitedUserRef = db.collection("users").doc(invitedUid);
        batch.update(invitedUserRef, { spaceIds: admin.firestore.FieldValue.arrayUnion(spaceId) });

        await batch.commit();
        return { success: true, message: "Miembro invitado y perfil actualizado." };

    } catch (e) {
        if (e instanceof functions.https.HttpsError) throw e;
        throw new functions.https.HttpsError("internal", `Error de BD: ${e}`);
    }
});


// Eliminar Miembro (por el Owner)
export const removeMemberFromSpace = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    const spaceId = data.spaceId;
    const userIdToRemove = data.userIdToRemove; 

    if (!callerUid || !spaceId || !userIdToRemove) {
        throw new functions.https.HttpsError("invalid-argument", "Faltan parámetros.");
    }

    const batch = db.batch();
    const spaceRef = db.collection("spaces").doc(spaceId);
    
    // 1. VERIFICACIÓN DE OWNER
    const spaceDoc = await spaceRef.get();
    const members = spaceDoc.data()?.members || {};
    
    if (members[callerUid] !== "owner") {
        throw new functions.https.HttpsError("permission-denied", "Solo el propietario puede eliminar miembros.");
    }
    
    // Comprobación de seguridad: No puede echarse a sí mismo (eso es 'leaveSpace') o a otro Owner (si es el único)
    if (userIdToRemove === callerUid && members[userIdToRemove] === 'owner' && Object.values(members).filter(r => r === 'owner').length === 1) {
         throw new functions.https.HttpsError("failed-precondition", "No puedes eliminar al último propietario.");
    }

    // Eliminar el miembro del Space
    batch.update(spaceRef, {
        [`members.${userIdToRemove}`]: admin.firestore.FieldValue.delete(),
    });

    // Eliminar el spaceId del perfil del usuario
    const removedUserRef = db.collection("users").doc(userIdToRemove);
    batch.update(removedUserRef, {
        spaceIds: admin.firestore.FieldValue.arrayRemove(spaceId),
    });

    await batch.commit();
    return { success: true };
});


// TAREA 5: Abandonar Space (Self-Service)
export const leaveSpaceSelfService = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    const spaceId = data.spaceId;

    if (!callerUid || !spaceId) {
        throw new functions.https.HttpsError("invalid-argument", "Faltan parámetros.");
    }

    const batch = db.batch();
    const spaceRef = db.collection("spaces").doc(spaceId);

    // 1. VERIFICACIÓN: El usuario no puede abandonar si es el único Owner
    const spaceDoc = await spaceRef.get();
    const members = spaceDoc.data()?.members || {};
    
    if (members[callerUid] === 'owner' && Object.values(members).filter(r => r === 'owner').length === 1) {
         throw new functions.https.HttpsError("failed-precondition", "El Space debe tener al menos un propietario restante.");
    }

    // 2. OPERACIÓN A: Eliminar al usuario del mapa 'members' del Space
    batch.update(spaceRef, {
        [`members.${callerUid}`]: admin.firestore.FieldValue.delete(),
    });

    // 3. OPERACIÓN B: Eliminar el spaceId de su propio perfil
    const callerUserRef = db.collection("users").doc(callerUid);
    batch.update(callerUserRef, {
        spaceIds: admin.firestore.FieldValue.arrayRemove(spaceId),
    });

    await batch.commit();
    return { success: true };
});


/**
 * Helper para borrar una colección entera en lotes.
 */
async function deleteCollection(
  collectionRef: admin.firestore.CollectionReference
) {
  const query = collectionRef.limit(100); 

  return new Promise<void>((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

/**
 * Función recursiva que borra un lote y se llama a sí misma
 * hasta que la colección está vacía.
 */
async function deleteQueryBatch(
  query: admin.firestore.Query,
  resolve: () => void,
  reject: (error: Error) => void
) {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error as Error);
  }
}