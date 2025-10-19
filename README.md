
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
  <img width="1080" height="2424" alt="Screenshot_1760897296" src="https://github.com/user-attachments/assets/c729175a-d071-404a-b537-1568d2cbdd6f" />


* Если товар уже есть на складе — увеличивать количество ✔️
* При добавлении существующего товара количество увеличивается ✔️
  ![Screen_recording_20251019_230511](https://github.com/user-attachments/assets/95ff67c7-02b7-4ab7-965a-761acc0f9481)

* Возможность просмотра всех остатков ✔️
  <img width="1080" height="2424" alt="Screenshot_1760896921" src="https://github.com/user-attachments/assets/d675240d-2097-40b6-a528-eae3f76925c2" />


**Бонус:**

* Удаление товара со склада (валидация количества) ✔️
  <img width="1080" height="2424" alt="Screenshot_1760897364" src="https://github.com/user-attachments/assets/26283e2c-df68-474a-b8e7-7f96bcb3f81c" />

* Фильтрация по складам ✔️
  <img width="459" height="387" alt="image" src="https://github.com/user-attachments/assets/aa65d109-58a6-40cf-a35c-39a3484a3c9c" />

* Подсчёт общего количества по всем складам ✔️
  <img width="1080" height="2424" alt="Screenshot_1760897461" src="https://github.com/user-attachments/assets/faa62bf0-91f6-4e8a-a7ec-2e2c41780350" />


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
  ![Screen_recording_20251019_231143](https://github.com/user-attachments/assets/accb0e8e-b5b2-4314-9301-fb48fe653e39)

---
### Полное видео
*Ссылка на Google Drive: https://drive.google.com/file/d/16c3biZX1Pt3elq57dfatOwitmnHb3731/view?usp=sharing
*Гифка
![Screen_recording_20251019_231737](https://github.com/user-attachments/assets/2ecaafda-c558-4b00-9901-1234f56a587b)

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
