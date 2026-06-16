pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string filePath: Quickshell.shellPath("generated/dashboard-todo.json")
    property var items: []

    function save() {
        todoFile.setText(JSON.stringify(root.items));
    }

    function todayKey() {
        return dateKey(new Date());
    }

    function dateKey(dateValue) {
        const year = dateValue.getFullYear();
        const month = String(dateValue.getMonth() + 1).padStart(2, "0");
        const day = String(dateValue.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function addTask(text, dateKeyValue) {
        const content = String(text || "").trim();
        if (!content.length)
            return;

        root.items = root.items.concat([
            {
                "id": `${Date.now()}-${Math.round(Math.random() * 100000)}`,
                "content": content,
                "done": false,
                "dateKey": dateKeyValue || todayKey(),
                "createdAt": Date.now()
            }
        ]);
        save();
    }

    function itemsForDate(dateKeyValue) {
        return root.items.filter(item => (item.dateKey || todayKey()) === dateKeyValue);
    }

    function countForDate(dateKeyValue) {
        return itemsForDate(dateKeyValue).length;
    }

    function toggle(index) {
        if (index < 0 || index >= root.items.length)
            return;

        const next = root.items.slice(0);
        next[index] = Object.assign({}, next[index], {
            "done": !next[index].done
        });
        root.items = next;
        save();
    }

    function toggleById(id) {
        const index = root.items.findIndex(item => item.id === id);
        toggle(index);
    }

    function remove(index) {
        if (index < 0 || index >= root.items.length)
            return;

        const next = root.items.slice(0);
        next.splice(index, 1);
        root.items = next;
        save();
    }

    function removeById(id) {
        const index = root.items.findIndex(item => item.id === id);
        remove(index);
    }

    FileView {
        id: todoFile

        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                root.items = Array.isArray(parsed) ? parsed.map(item => Object.assign({
                        "id": `${Date.now()}-${Math.round(Math.random() * 100000)}`,
                        "dateKey": todayKey()
                    }, item)) : [];
            } catch (error) {
                root.items = [];
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.save();
        }
    }
}
