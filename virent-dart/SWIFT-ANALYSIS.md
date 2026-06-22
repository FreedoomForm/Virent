# Swift Competitor App — 7 Screens Analyzed

## Key features to adopt from Swift:

### 1. Custom Numeric Keypad (Auth screen)
- 4x3 grid with large number buttons
- Built-in backspace key
- No system keyboard needed — cleaner UX
- Country flag selector + phone code dropdown

### 2. OTP with 4-box input + error states
- 4 boxes (not 6 like ours)
- "Неверный код" (red) + "Осталось 2 попытки"
- Countdown timer "Запросить код повторно через 0:15"

### 3. Map-centric with "Куда едем?" search bar
- Search bar on top of map (always visible)
- Shows recent locations below search
- Address suggestions with autocomplete

### 4. Route planning with battery warning
- "Заряд может не хватить для этой поездки" warning
- Shows route on map before starting
- "Забронировать самокат" (Reserve) button

### 5. Speed control zone notification
- "Зона контроля скорости" popup with "Хорошо" button
- Visual zone indication on map

### 6. Parking zone enforcement
- "Вы находитесь вне зоны парковки" warning
- Photo capture required to end ride
- "Продолжить маршрут" option

### 7. Ride stats inline
- "Цена 50₽" + "В пути 0:45" on one line
- Compact, always visible during ride

### 8. Payment methods inline in booking
- "Новая карта" + "Добавить карту"
- T-Pay, Сбер-Pay, СБП options
- All visible in booking modal (no separate screen)

### 9. Profile with driving school stats
- "Школа вождения 34 км" — gamification
- Ride history with map thumbnails
- Support chat link
- Promocodes section

### 10. Booking flow: Map → Route → QR → Ride → Photo → End
- Clear step-by-step flow
- "Путь до самоката" (walking distance to scooter)
- QR scan to unlock
- Photo to end ride
