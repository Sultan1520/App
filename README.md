![Screen_recording_20251019_225007](https://github.com/user-attachments/assets/efbb1bec-15ed-4c21-8c3e-6652b382880d)<img width="427" height="321" alt="image" src="https://github.com/user-attachments/assets/262cafbe-0c81-4b39-bb6f-46475fada8dd" /><img width="1080" height="2424" alt="Screenshot_1760896716" src="https://github.com/user-attachments/assets/1fe344f8-1198-4c89-b7c5-4ca47b7cb62e" /><img width="1080" height="2424" alt="Screenshot_1760895701" src="https://github.com/user-attachments/assets/7f079ab7-c045-4267-bb84-d35ad9473deb" /><img width="1080" height="2424" alt="Screenshot_1760895701" src="https://github.com/user-attachments/assets/8472c7f1-d904-498e-829e-99272401aeb3" /><img width="360" height="116" alt="image" src="https://github.com/user-attachments/assets/cf3f1299-8bb9-4e22-b1eb-6a648d5db379" /># Flutter Shop App

Приложение для управления товарами и остатками на складе.
Все данные сохраняются локально с помощью базы данных **SQFLite**, при повторном запуске состояние полностью восстанавливается.
Поддерживается **светлая и тёмная темы интерфейса**.

---

## Запуск проекта

### Требования

* Flutter SDK 
* Android Studio или VS Code
* Android/iOS эмулятор или физическое устройство

### Установка и запуск

```bash
git clone https://github.com/Sultan1520/App.git
cd App
flutter pub get
flutter run
```

Приложение автоматически запустится на подключённом эмуляторе (в моём случае Google Pixels 9)

---

## ⚙️ Основной функционал

### Управление товарами 

**Основная часть:**

* Добавление нового товара ✔️
  <img width="1080" height="2424" alt="Screenshot_1760895707" src="https://github.com/user-attachments/assets/918e20f9-dfe8-45e4-b59d-c13d97ca3756" />

* Валидация GTIN (ровно 13 цифр, только цифры) ✔️
  <img width="360" height="116" alt="image" src="https://github.com/user-attachments/assets/0d10faf5-6ff4-49e5-803e-9e67e81759ed" />

* Редактирование и удаление товаров ✔️
  ![Screen_recording_20251019_225007](https://github.com/user-attachments/assets/651895f6-ba8d-46ca-9f10-505b75da4790)

* Список товаров с отображением: *название, цена, дата создания* ✔️
  <img width="1080" height="2424" alt="Screenshot_1760895701" src="https://github.com/user-attachments/assets/66adb168-4176-4f00-ad76-fcbdffcad871" />

* Сортировка по дате создания и названию ✔️
  <img width="464" height="601" alt="image" src="https://github.com/user-attachments/assets/ef5afa28-2321-41a1-adac-9cbc80d7b8a9" />


**Бонус:**

* Добавление изображения для товара ✔️
  <img width="427" height="321" alt="image" src="https://github.com/user-attachments/assets/b1b33156-058e-4c58-980d-b09e539937a3" />

* Поиск по GTIN ✔️
  <img width="464" height="601" alt="image" src="https://github.com/user-attachments/assets/951f4c7e-2634-4865-8065-6528fb8fd448" />

* Подтверждение удаления (модальное окно) ✔️
  <img width="1080" height="2424" alt="Screenshot_1760896716" src="https://github.com/user-attachments/assets/dc1dfe5f-3a32-4e30-80c5-de150b6f5397" />


---

### Управление остатками

**Основная часть:**

* Добавление остатков (склад, GTIN, количество)  ✔️
* Если товар уже есть на складе — увеличивать количество ✔️
* При добавлении существующего товара количество увеличивается ✔️
* Возможность просмотра всех остатков ✔️

**Бонус:**

* Удаление товара со склада (валидация количества) ✔️
* Фильтрация по складам ✔️
* Подсчёт общего количества по всем складам ✔️

---

### Сохранение состояния

**Основная часть:**

* Все данные сохраняются в SQFLite ✔️
* После перезапуска состояние полностью восстанавливается ✔️

**Бонус:**

* Архитектура: `repo → service → usecase` ✔️
* Интерфейсы репозиториев и сервисов позволяют заменить хранилище на внешнюю БД в будущем ✔️

---

### Интерфейс пользователя

**Основная часть:**

* Базовый UI для товаров и остатков ✔️
* Карточки и кнопки действий ✔️
* Минимальная стилизация ✔️

**Бонус:**

* Адаптивный дизайн ✔️
* Переключение между светлой и тёмной темой ✔️

---

##  Хранение данных

Все данные сохраняются в **SQFLite**:

* Таблицы `products` и `stocks`
* CRUD-операции через репозитории
* Данные восстанавливаются при старте приложения

---

##  Темная и светлая темы

* Реализовано переключение между тёмной и светлой темой
* Настройки темы сохраняются с помощью **shared_preferences**

---

##  Структура проекта

```
lib/
 ├── main.dart                # Точка входа
 ├── screens/
 │    ├── main_screen.dart    # Главный экран с навигацией
 │    ├── product_screen.dart # Управление товарами
 │    └── stock_screen.dart   # Управление остатками
 ├── models/                  # Модели данных
 ├── repositories/            # Репозитории (repo layer)
```

---

## Используемые пакеты

* **sqflite** — локальная база данных
* **path_provider** — путь к локальному хранилищу
* **shared_preferences** — сохранение темы
* **provider** — управление состоянием
