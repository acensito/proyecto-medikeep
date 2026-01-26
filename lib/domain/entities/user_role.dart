
/// Clase que define los roles de usuario
enum UserRole {
  owner,   // PROPIETARIO: Puede editar espacios y sus usuarios, contenedores y medicamentos 
  editor,  // EDITOR: Solo puede editar contenedores y medicamentos
  viewer   // VISOR: Solo puede ver
}