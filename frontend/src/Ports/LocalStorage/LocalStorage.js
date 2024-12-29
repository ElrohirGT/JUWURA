function setLocalStorageCallback([key, value]) {
    try {
        localStorage.setItem(key, value);
    } catch (e) {
        console.error("Failed to set localStorage value:", e);
    }
}

function getLocalStorageCallbackConstructor(app) {
    return (key) => {
        try {
            const value = localStorage.getItem(key);
            app.ports.onValueLocalStorage.send(value);
        } catch (e) {
            console.error("Failed to get localStorage value:", e);
            app.ports.onValueLocalStorage.send(null);
        }
    };
}

// Set up ports
export function initializeLocalStoragePorts(app) {
    app.ports.setLocalStorage.subscribe(setLocalStorageCallback);
    app.ports.getLocalStorage.subscribe(getLocalStorageCallbackConstructor(app));}