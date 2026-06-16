pragma ComponentBehavior: Bound
pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    readonly property string latitude: Quickshell.env("QS_WEATHER_LAT") || "43.2389"
    readonly property string longitude: Quickshell.env("QS_WEATHER_LON") || "76.8897"
    property string city: Quickshell.env("QS_WEATHER_CITY") || "Almaty"
    property string condition: "Weather unavailable"
    property string temperature: "--"
    property string feelsLike: "--"
    property string humidity: "--"
    property string wind: "--"
    property int weatherCode: -1
    property bool isDay: true
    property bool ready: false

    readonly property string iconName: iconForCode(weatherCode, isDay)

    function iconForCode(code, day) {
        if (code === 0)
            return day ? "sun-medium" : "moon-star";
        if (code === 1)
            return day ? "cloud-sun" : "cloud-moon";
        if (code === 2)
            return day ? "cloud-sun" : "cloud-moon";
        if (code === 3 || code === 45 || code === 48)
            return "cloud-fog";
        if (code >= 51 && code <= 57)
            return "cloud-drizzle";
        if (code >= 61 && code <= 67)
            return "cloud-rain";
        if (code >= 80 && code <= 82)
            return "cloud-rain-wind";
        if (code >= 71 && code <= 86)
            return "cloud-snow";
        if (code >= 95)
            return "cloud-lightning";
        return "cloud";
    }

    function conditionForCode(code) {
        const conditions = {
            "0": "Clear",
            "1": "Mostly clear",
            "2": "Partly cloudy",
            "3": "Overcast",
            "45": "Fog",
            "48": "Fog",
            "51": "Light drizzle",
            "53": "Drizzle",
            "55": "Heavy drizzle",
            "56": "Freezing drizzle",
            "57": "Freezing drizzle",
            "61": "Light rain",
            "63": "Rain",
            "65": "Heavy rain",
            "66": "Freezing rain",
            "67": "Freezing rain",
            "71": "Light snow",
            "73": "Snow",
            "75": "Heavy snow",
            "77": "Snow grains",
            "80": "Rain showers",
            "81": "Rain showers",
            "82": "Heavy showers",
            "85": "Snow showers",
            "86": "Heavy snow showers",
            "95": "Thunderstorm",
            "96": "Thunderstorm",
            "99": "Thunderstorm"
        };
        return conditions[String(code)] || "Weather";
    }

    function refresh() {
        if (!SettingsService.weatherService)
            return;

        if (weatherProc.running)
            return;

        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m&timezone=auto&forecast_days=1";
        weatherProc.command = ["curl", "-fsSL", "--max-time", "8", url];
        weatherProc.running = true;
    }

    Process {
        id: weatherProc

        stdout: StdioCollector {
            id: weatherOut
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                return;

            try {
                const data = JSON.parse(weatherOut.text);
                const current = data.current || {};
                root.weatherCode = Number(current.weather_code);
                root.isDay = Number(current.is_day) !== 0;
                root.temperature = Number.isFinite(Number(current.temperature_2m)) ? `${Math.round(Number(current.temperature_2m))}°` : "--";
                root.feelsLike = Number.isFinite(Number(current.apparent_temperature)) ? `${Math.round(Number(current.apparent_temperature))}°` : "--";
                root.humidity = Number.isFinite(Number(current.relative_humidity_2m)) ? `${Math.round(Number(current.relative_humidity_2m))}%` : "--";
                root.wind = Number.isFinite(Number(current.wind_speed_10m)) ? `${Math.round(Number(current.wind_speed_10m))} km/h` : "--";
                root.condition = root.conditionForCode(root.weatherCode);
                root.ready = true;
            } catch (error) {
                console.warn("Failed to parse weather response", error);
            }
        }
    }

    Timer {
        interval: 1800000
        running: SettingsService.weatherService
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
