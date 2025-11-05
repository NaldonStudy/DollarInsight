// 001-init.js
db = db.getSiblingDB('dollar_insight');
db.createUser({
  user: 'di_user',
  pwd: 'ssafy',
  roles: [{ role: 'readWrite', db: 'dollar_insight' }]
});
