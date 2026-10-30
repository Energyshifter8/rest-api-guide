# Rest API Guide

**Ruby on Rails 8 + MySQL + Docker** ашиглан бүтээсэн энгийн REST API.
Пост (`Post`) болон сэтгэгдэл (`Comment`) гэсэн 2 хүснэгттэй бөгөөд бүх CRUD үйлдлийг JSON-оор хийнэ.

| Технологи | Хувилбар |
|---|---|
| Ruby | 4.0.9 (`.ruby-version`) |
| Rails | 8.1 (`--api` горим) |
| MySQL | 8.4 (Docker container) |
| API баримт бичиг | Swagger UI (OpenAPI 3) |

---

## Агуулга

1. [Хурдан эхлэх](#1-хурдан-эхлэх)
2. [Ерөнхий зураглал](#2-ерөнхий-зураглал--хүсэлт-хэрхэн-явдаг-вэ)
3. [Төслийн бүтэц](#3-төслийн-бүтэц)
4. [Docker ба MySQL](#4-docker-ба-mysql)
5. [Model ба Migration](#5-model-ба-migration)
6. [Routes ба Controller](#6-routes-ба-controller)
7. [Endpoint-ууд](#7-endpoint-ууд)
8. [Swagger — API баримт бичиг](#8-swagger--api-баримт-бичиг)
9. [Туршиж үзэх (curl)](#9-туршиж-үзэх-curl)
10. [Өгөгдлийг шууд харах](#10-өгөгдлийг-шууд-харах)
11. [Түгээмэл командууд](#11-түгээмэл-командууд)

---

## 1. Хурдан эхлэх

Шаардлага: **Docker**, **Ruby 4.0.9** ([mise](https://mise.jdx.dev) ашиглахыг зөвлөнө), MySQL client сан (`libmysqlclient` / `mariadb-libs`).

```sh
git clone https://github.com/Energyshifter8/rest-api-guide.git
cd rest-api-guide

bundle install            # 1. Gem-үүдийг суулгах
docker compose up -d      # 2. MySQL-ийг Docker дээр асаах
bin/rails db:prepare      # 3. DB үүсгэх + migration + seed (жишээ өгөгдөл)
bin/rails server          # 4. API асаах → http://localhost:3000
```

Дараа нь хөтөч дээр:

- **http://localhost:3000/api-docs** — Swagger (бүх endpoint-ийг товчоор туршина)
- **http://localhost:3000/posts** — JSON шууд харах

---

## 2. Ерөнхий зураглал — хүсэлт хэрхэн явдаг вэ?

```
 [curl / Swagger / Postman / Frontend]
              │  HTTP хүсэлт (JSON)
              ▼
 ┌──────────────────── Rails (localhost:3000) ────────────────────┐
 │  1. config/routes.rb  →  URL-ийг аль controller руу явуулахыг   │
 │                          шийднэ                                 │
 │  2. Controller        →  параметр шалгаж, model-ийг дуудна      │
 │  3. Model             →  дүрэм (validation), холбоо, SQL        │
 └───────────────────────────────┬─────────────────────────────────┘
                                 │ SQL
                                 ▼
               [MySQL — Docker container, порт 3306]
```

**Жишээ:** `GET /posts/1` хүсэлт ирэхэд

1. **Routes** → `PostsController#show` руу явуулна
2. **Controller** → `Post.find(1)` гэж дуудна
3. **Model** → MySQL руу `SELECT * FROM posts WHERE id = 1` илгээнэ
4. **Controller** → үр дүнг `render json:` ашиглан JSON болгож буцаана

---

## 3. Төслийн бүтэц

```
rest-api-guide/
├── docker-compose.yml               ← MySQL-ийг Docker дээр асаах тохиргоо
├── Gemfile                          ← Ашиглаж буй сангууд (rails, mysql2 ...)
├── config/
│   ├── database.yml                 ← Rails ямар DB-д холбогдох (127.0.0.1:3306, root)
│   └── routes.rb                    ← URL → Controller холболт
├── app/
│   ├── models/
│   │   ├── post.rb                  ← Post: has_many :comments
│   │   └── comment.rb               ← Comment: belongs_to :post
│   └── controllers/
│       ├── application_controller.rb  ← Бүх controller-ийн эх; 404-ийг JSON-оор буцаана
│       ├── posts_controller.rb        ← Post-ийн CRUD
│       └── comments_controller.rb     ← Comment-ийн CRUD
├── db/
│   ├── migrate/                     ← Хүснэгт үүсгэх/өөрчлөх "заавар" файлууд
│   ├── schema.rb                    ← DB-ийн одоогийн бүтэц (автоматаар үүснэ, гараар засахгүй)
│   └── seeds.rb                     ← Жишээ өгөгдөл
├── public/api-docs/
│   ├── index.html                   ← Swagger UI хуудас
│   └── openapi.yaml                 ← Endpoint-уудын тодорхойлолт (монгол тайлбартай)
└── test/                            ← Тестүүд
```

`--api` горим гэдэг нь HTML view, CSS, JS байхгүй, **зөвхөн JSON** буцаадаг хөнгөн Rails гэсэн үг.

---

## 4. Docker ба MySQL

`docker-compose.yml` нь `mysql:8.4` image-аас **rest-api-guide-mysql** нэртэй container үүсгэдэг:

| Тохиргоо | Утга | Тайлбар |
|---|---|---|
| Порт | `127.0.0.1:3306` | Зөвхөн өөрийн компьютерээс хандана |
| Хэрэглэгч | `root`, нууц үггүй | `config/database.yml`-тэй таарна (зөвхөн development-д) |
| Volume | `mysql_data` | Container унтарсан ч өгөгдөл устахгүй |
| Healthcheck | `mysqladmin ping` | MySQL бэлэн болсныг шалгана |

```sh
docker compose up -d      # MySQL асаах (background-д)
docker compose ps         # Төлөв харах (healthy байх ёстой)
docker compose logs -f    # MySQL-ийн лог харах
docker compose stop       # Унтраах (өгөгдөл үлдэнэ)
docker compose down -v    # Бүрэн устгах — ӨГӨГДӨЛ Ч УСТНА!
```

Rails нь `config/database.yml` дээрх тохиргоогоор MySQL-д холбогдоно. Өөр host ашиглах бол `DB_HOST` орчны хувьсагчаар солино:

```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4        # Кирилл, emoji зөв хадгална
  username: root
  password:
  host: <%= ENV.fetch("DB_HOST") { "127.0.0.1" } %>

development:
  database: rest_api_guide_development
test:
  database: rest_api_guide_test
```

---

## 5. Model ба Migration

### Model үүсгэсэн командууд

```sh
rails generate model Post title:string content:string
rails generate model Comment post:references comment:string
```

Команд бүр 2 зүйл үүсгэдэг:

- **Model** (`app/models/post.rb`) — `posts` хүснэгттэй холбогдох Ruby класс
- **Migration** (`db/migrate/..._create_posts.rb`) — хүснэгт үүсгэх заавар

`post:references` нь `comments` хүснэгтэд `post_id` багана + index + **foreign key** нэмдэг. Ингэснээр нэг пост олон сэтгэгдэлтэй байх холбоо үүснэ.

### Хүснэгтүүд

```
posts                         comments
├── id          (PK)          ├── id          (PK)
├── title       string        ├── post_id     (FK → posts.id)
├── content     string        ├── comment     string
├── created_at                ├── created_at
└── updated_at                └── updated_at

        posts 1 ──────────< comments (олон)
```

### Model доторх дүрмүүд

```ruby
class Post < ApplicationRecord
  has_many :comments, dependent: :destroy   # Пост устгахад сэтгэгдлүүд нь хамт устна
  validates :title, presence: true          # Гарчиггүй бол 422 алдаа
end

class Comment < ApplicationRecord
  belongs_to :post                          # Заавал нэг постод харьяалагдана
  validates :comment, presence: true
end
```

### Migration гэж юу вэ?

Migration бол **DB-ийн бүтцийн өөрчлөлтийн түүх**. SQL гараар бичихийн оронд Ruby файл үүсгээд ажиллуулна. Багийн гишүүн бүр ижил бүтэцтэй DB-тэй болно.

```sh
bin/rails db:create      # MySQL дээр DB үүсгэнэ
bin/rails db:migrate     # Ажиллаагүй migration-уудыг ажиллуулна → db/schema.rb шинэчлэгдэнэ
bin/rails db:rollback    # Сүүлийн migration-ийг буцаана
bin/rails db:seed        # db/seeds.rb-ийн өгөгдлийг оруулна
bin/rails db:prepare     # Дээрхийг бүгдийг нь хэрэгтэй бол хийнэ (create + migrate + seed)
```

Шинэ багана нэмэх жишээ:

```sh
bin/rails generate migration AddAuthorToPosts author:string
bin/rails db:migrate
```

---

## 6. Routes ба Controller

### Routes (`config/routes.rb`)

```ruby
resources :posts do
  resources :comments    # nested — сэтгэгдэл заавал нэг постын дор байна
end
```

Энэ 2 мөр нь доорх 7 + 7 route-ийг автоматаар үүсгэдэг. Бүгдийг `bin/rails routes` командаар харна.

### Controller

Controller-ийн action бүр нэг HTTP хүсэлтэд харгалзана:

| Action | Юу хийдэг вэ |
|---|---|
| `index` | Жагсаалт буцаана |
| `show` | Нэгийг буцаана |
| `create` | Шинээр үүсгэнэ |
| `update` | Засна |
| `destroy` | Устгана |

**Strong parameters** — `params.expect(post: [:title, :content])` нь зөвхөн зөвшөөрсөн талбаруудыг хүлээн авна. Хэрэглэгч `id` гэх мэт хориотой талбар илгээвэл үл тооно. Тиймээс body-г `{"post": {...}}` хэлбэрээр илгээдэг.

**Алдаа:** `ApplicationController` дээрх `rescue_from ActiveRecord::RecordNotFound` нь олдохгүй бичлэгийг `404 {"error": "..."}` JSON болгож буцаадаг.

---

## 7. Endpoint-ууд

### Posts

| Method | URL | Тайлбар | Амжилттай хариу |
|---|---|---|---|
| `GET` | `/posts` | Бүх пост | `200` |
| `POST` | `/posts` | Пост үүсгэх | `201` |
| `GET` | `/posts/:id` | Нэг пост (сэтгэгдлүүдтэй нь) | `200` |
| `PATCH` / `PUT` | `/posts/:id` | Пост засах | `200` |
| `DELETE` | `/posts/:id` | Пост устгах (сэтгэгдлүүд хамт устна) | `204` |

### Comments

| Method | URL | Тайлбар | Амжилттай хариу |
|---|---|---|---|
| `GET` | `/posts/:post_id/comments` | Постын бүх сэтгэгдэл | `200` |
| `POST` | `/posts/:post_id/comments` | Сэтгэгдэл нэмэх | `201` |
| `GET` | `/posts/:post_id/comments/:id` | Нэг сэтгэгдэл | `200` |
| `PATCH` / `PUT` | `/posts/:post_id/comments/:id` | Сэтгэгдэл засах | `200` |
| `DELETE` | `/posts/:post_id/comments/:id` | Сэтгэгдэл устгах | `204` |

### Хариуны кодууд

| Код | Утга |
|---|---|
| `200 OK` | Амжилттай |
| `201 Created` | Амжилттай үүсгэсэн |
| `204 No Content` | Амжилттай устгасан (хариу хоосон) |
| `404 Not Found` | Ийм id-тай бичлэг олдсонгүй |
| `422 Unprocessable Content` | Өгөгдөл буруу (жишээ нь гарчиг хоосон) |

---

## 8. Swagger — API баримт бичиг

Сервер асаалттай үед **http://localhost:3000/api-docs** хаягийг нээнэ.

1. Endpoint дээр дарж нээнэ
2. Параметр (`id`) болон body-г бөглөнө
3. **Execute** дарна
4. Доор нь явсан `curl` команд, сервэрийн хариу (код, body, header) харагдана

Swagger нь 2 файлаас бүрдэнэ:

- `public/api-docs/openapi.yaml` — бүх endpoint, параметр, хариуны тодорхойлолт (монгол тайлбартай). **Шинэ endpoint нэмбэл энэ файлыг шинэчилнэ.**
- `public/api-docs/index.html` — Swagger UI-г ачаалж дээрх YAML-ыг харуулдаг хуудас

Rails нь `public/` хавтас доторх файлуудыг шууд үйлчилдэг тул нэмэлт gem хэрэггүй.

---

## 9. Туршиж үзэх (curl)

```sh
# Бүх пост
curl localhost:3000/posts

# Пост үүсгэх
curl -X POST localhost:3000/posts \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"Сайн уу","content":"Миний пост"}}'

# Сэтгэгдэл нэмэх (1 = постын id)
curl -X POST localhost:3000/posts/1/comments \
  -H "Content-Type: application/json" \
  -d '{"comment":{"comment":"Сайхан пост!"}}'

# Постыг сэтгэгдэлтэй нь харах
curl localhost:3000/posts/1

# Засах
curl -X PATCH localhost:3000/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"Шинэ гарчиг"}}'

# Устгах
curl -X DELETE localhost:3000/posts/1
```

Жишээ хариу (`GET /posts/1`):

```json
{
  "id": 1,
  "title": "Анхны пост",
  "content": "Rails REST API-ийн жишээ пост",
  "created_at": "2026-10-30T07:06:13.944Z",
  "updated_at": "2026-10-30T07:06:13.944Z",
  "comments": [
    { "id": 1, "post_id": 1, "comment": "Анхны сэтгэгдэл", "created_at": "...", "updated_at": "..." }
  ]
}
```

---

## 10. Өгөгдлийг шууд харах

**Rails console** (Ruby-гаар):

```sh
bin/rails console
```
```ruby
Post.all
Post.first.comments
Post.create!(title: "Console-оос", content: "...")
```

**MySQL** (SQL-ээр):

```sh
docker exec -it rest-api-guide-mysql mysql -uroot --default-character-set=utf8mb4 rest_api_guide_development
```
```sql
SHOW TABLES;
SELECT * FROM posts;
SELECT * FROM comments;
```

> `--default-character-set=utf8mb4` заавал хэрэгтэй, үгүй бол кирилл үсэг `????` болж харагдана (DB-д зөв хадгалагдсан ч).

**Лог:** сервер ажиллаж байхад хүсэлт бүрийн SQL болон хариу `log/development.log` болон серверийн terminal дээр харагдана.

---

## 11. Түгээмэл командууд

| Команд | Үйлдэл |
|---|---|
| `docker compose up -d` | MySQL асаах |
| `bin/rails server` | API асаах (порт 3000) |
| `bin/rails routes` | Бүх route харах |
| `bin/rails console` | Ruby console |
| `bin/rails db:migrate` | Migration ажиллуулах |
| `bin/rails db:seed` | Жишээ өгөгдөл оруулах |
| `bin/rails test` | Тест ажиллуулах |
| `bin/rubocop` | Кодын стиль шалгах |
| `bin/brakeman` | Аюулгүй байдлын шалгалт |
