"use strict";
// interface Room {
//   name: string;
//   participants: string[];
// }
// const rooms: Room[] = [];
// // Criar ou adicionar um participante a uma sala
// export const createRoom = (roomName: string, username: string): void => {
//   const existingRoom = rooms.find((room) => room.name === roomName);
//   if (existingRoom) {
//     if (!existingRoom.participants.includes(username)) {
//       existingRoom.participants.push(username);
//     }
//   } else {
//     rooms.push({ name: roomName, participants: [username] });
//   }
// };
// // Remover um participante de uma sala
// export const removeParticipant = (roomName: string, username: string): void => {
//   const roomIndex = rooms.findIndex((room) => room.name === roomName);
//   if (roomIndex !== -1) {
//     const room = rooms[roomIndex];
//     room.participants = room.participants.filter((user) => user !== username);
//     if (room.participants.length === 0) {
//       rooms.splice(roomIndex, 1);
//     }
//   }
// };
// // chatgpt: com a nova logica do meu codigo, parece q agora o getRoomParticipants retorna sempre vazio, corrija
// // Obter participantes de uma sala
// export const getRoomParticipants = (roomName: string): string[] => {
//   const room = rooms.find((room) => room.name === roomName);
//   return room?.participants || [];
// };
// // Obter lista de salas disponíveis
// export const getAvailableRooms = (): string[] => {
//   return rooms.map((room) => room.name);
// };
