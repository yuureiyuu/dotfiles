pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool animationsEnabled: true
    property bool clock24h: false
    property bool showNotifications: true
    property bool compactIsland: false
    property bool islandEnabled: true
    property bool weatherService: true
    property bool systemStatsService: true
    property bool nowPlayingService: true
    property bool batteryService: true
    property bool desktopClock: false
    property bool wallpaperDim: false
    property real interfaceScale: 1
    property real backgroundBlur: 0.18
    property string shellLanguage: "system"
    property string keyboardLayout: "current"
    property string barPosition: "right"

    function duration(ms) {
        return animationsEnabled ? ms : 0;
    }

    function scaled(value) {
        return Math.round(value * interfaceScale);
    }

    function resetGeneral() {
        shellLanguage = "system";
        keyboardLayout = "current";
        animationsEnabled = true;
        clock24h = false;
        showNotifications = true;
    }

    function resetInterface() {
        compactIsland = false;
        islandEnabled = true;
        interfaceScale = 1;
        barPosition = "right";
    }

    function setShellLanguage(language) {
        shellLanguage = language;
    }

    function t(source) {
        if (shellLanguage !== "ru")
            return source;

        const ru = {
            "Settings": "Настройки",
            "Shell": "Shell",
            "General": "Основное",
            "Services": "Сервисы",
            "Background": "Фон",
            "Interface": "Интерфейс",
            "About": "О shell",
            "Language": "Язык",
            "Keyboard layout": "Раскладка клавиатуры",
            "System": "Система",
            "English": "Английский",
            "Current": "Текущая",
            "Animations": "Анимации",
            "24-hour clock": "24-часовые часы",
            "Notifications": "Уведомления",
            "Weather": "Погода",
            "System stats": "Системная статистика",
            "Now playing": "Сейчас играет",
            "Battery": "Батарея",
            "Wallpaper": "Обои",
            "Desktop clock": "Часы на рабочем столе",
            "Wallpaper dim": "Затемнение обоев",
            "Background blur": "Размытие фона",
            "No wallpaper selected": "Обои не выбраны",
            "Compact island": "Компактный island",
            "Bar position": "Позиция bar",
            "Right": "Справа",
            "Top": "Сверху",
            "Left": "Слева",
            "Interface scale": "Масштаб интерфейса",
            "Island": "Island",
            "Reset": "Сбросить",
            "Home": "Главная",
            "Plan": "План",
            "Spaces": "Пространства",
            "Control": "Управление",
            "Audio": "Аудио",
            "History": "История",
            "Theme": "Тема",
            "Dark theme": "Тёмная тема",
            "Light theme": "Светлая тема",
            "Bluetooth": "Bluetooth",
            "Bluetooth enabled": "Bluetooth включён",
            "Discovery": "Поиск устройств",
            "Connected device": "Подключённое устройство",
            "Devices": "Устройства",
            "Connected": "Подключено",
            "Paired": "Сопряжено",
            "Available": "Доступно",
            "Forget": "Забыть",
            "Pair": "Сопрячь",
            "Connect": "Подключить",
            "Back": "Назад",
            "Search apps or :wal": "Поиск приложений или :wal",
            "System Monitor": "Системный монитор",
            "System and process monitoring": "Мониторинг системы и процессов",
            "No notifications": "Нет уведомлений",
            "No title": "Без заголовка",
            "Clear": "Очистить",
            "Notification history is empty.": "История уведомлений пуста.",
            "Add task": "Добавить задачу",
            "Past date": "Прошедшая дата",
            "Timer": "Таймер",
            "Running": "Идёт",
            "Paused": "Пауза",
            "Ready": "Готов",
            "remaining": "осталось",
            "selected": "выбрано",
            "Nothing is playing": "Ничего не играет",
            "MPRIS player": "MPRIS-плеер",
            "User": "Пользователь",
            "Uptime": "Аптайм",
            "Focus session in progress.": "Фокус-сессия идёт.",
            "Duration prepared.": "Длительность подготовлена.",
            "No duration selected.": "Длительность не выбрана.",
            "hours": "часы",
            "min": "мин",
            "sec": "сек"
        };

        return ru[source] || source;
    }

    function setKeyboardLayout(layout) {
        keyboardLayout = layout;
        if (layout !== "current")
            Quickshell.execDetached(["hyprctl", "keyword", "input:kb_layout", layout]);
    }

    function setBarPosition(position) {
        barPosition = position;
    }

    function setBackgroundBlur(value) {
        backgroundBlur = Math.max(0, Math.min(1, value));
        const enabled = backgroundBlur > 0.01 ? "true" : "false";
        const size = Math.max(1, Math.round(2 + backgroundBlur * 18)).toString();
        const passes = Math.max(1, Math.round(1 + backgroundBlur * 3)).toString();
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", enabled]);
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:size", size]);
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:passes", passes]);
    }
}
