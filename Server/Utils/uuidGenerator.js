const User = require('../Models/User');

function generateUserId() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';

  const letterPart = Array.from({ length: 3 }, () =>
    letters[Math.floor(Math.random() * letters.length)]
  ).join('');

  const numberPart = Array.from({ length: 4 }, () =>
    digits[Math.floor(Math.random() * digits.length)]
  ).join('');

  return letterPart + numberPart;
}

async function generateUniqueUUID() {
  let uuid;
  let exists;

  do {
    uuid = generateUserId();
    exists = await User.exists({ uuid });
  } while (exists);

  return uuid;
}

module.exports = generateUniqueUUID;
