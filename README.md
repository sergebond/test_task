# test_task


Запуск приложения 
``` make deps && make run ```

Тестовое задания для кандидатов на позицию Erlang Middle developer ZiMAD Infrastructure
Задание: собрать простой сервер для работы с игровыми профилями пользователей.
Типовые данные, которые должны присутствовать в профиле: 
```
{"uid": "<some_string>", 
"nickname": "<some_string>", 
"coins": 100,
"stars": 0,
"level": 0}
```

// Уникальный id игрока, присваивается при регистрации

// Уникальное имя игрока, записывается при регистрации

// Баланс пользователя в монетах, 100 монет выдаётся при регистрации // Игровые звёздочки, покупаются по цене 1звезда=10монет

// Игровой уровень игрока

Протокол:
1. Регистрация пользователя: register(nickname) returns uid.
Создание профиля с записью в него никнейма. Отдаём пользователю id созданного профиля.
```
    curl  http://localhost:6163/register -d 'nickname=sergey'
    {"result":"ok","user_id":"cfe74ffce19725b649a58c767cf804fa2e18ef54"}
```

2. Авторизация зарегистрированного пользователя: authorize(uid) returns auth_token.
Создание сессии для пользователя, срок жизни 15 минут. Работа с авторизованными запросами при помощи выданного токена. 3. Авторизованный запрос на получение профиля: get_profile(auth_token) returns profile_json.
```
    curl  http://localhost:6163/auth -d 'user_id=cfe74ffce19725b649a58c767cf804fa2e18ef54'
    {"result":"ok","token":"464348f31fccaec7e2ced1ab91e42808f6888ab79bf0bd2d192f7c6945b57ccc","user_id":"cfe74ffce19725b649a58c767cf804fa2e18ef54","expires":1567936731}
```
3.Получение профиля пользователя в виде json-документа.
```
curl http://localhost:6163/api/1/json -d '{"type":"get", "obj":"profile",  "token":"007e39da16155a81bece911d326b5bc5c90232c1f0967b812058599c634e460d"}'
{"result":"ok","id":"cfe74ffce19725b649a58c767cf804fa2e18ef54","nickname":"sergey","coins":80,"stars":20,"level":0}
```
4. Авторизованный запрос победы на игровом уровне: win_level(auth_token)
Увеличение в профиле значения текущего уровня.
   ```
    curl http://localhost:6163/api/1/json -d '{"type":"get", "obj":"profile","token":"464348f31fccaec7e2ced1ab91e42808f6888ab79bf0bd2d192f7c6945b57ccc"}'
    {"result":"ok","id":"cfe74ffce19725b649a58c767cf804fa2e18ef54","nickname":"sergey","coins":80,"stars":20,"level":0} 
    ```

5. Авторизованный запрос на покупку звёзд: buy_stars(auth_token, stars_count) returns {"stars": <обновлённое кол-во звёзд>, "status": <статус операции>}.
```
    curl http://localhost:6163/api/1/json -d '{"type":"buy", "obj":"stars", "count":"10", "token":"007e39da16155a81bece911d326b5bc5c90232c1f0967b812058599c634e460d"}'
    {"result":"ok","user_id":"cfe74ffce19725b649a58c767cf804fa2e18ef54","coins_remain":90,"stars_count":10}
```
6. Авторизованный запрос на удаление профиля по запросу GDPR: gdpr_erase_profile(auth_token) returns {"status": "<статус операции>"}.
   ```
    curl  http://localhost:6163/api/1/json -d '{"type":"erase", "obj":"profile",  "token":"d08fd69e3a4d2c782462a5f239bc496fd0b2474380e1e585ab0d1b73f6e871a8"}'
    {"result":"ok"}
    ```
    
