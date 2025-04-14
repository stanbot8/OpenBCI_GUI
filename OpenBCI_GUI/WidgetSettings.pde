import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

//Used for Widget Dropdown Enums
interface IndexingInterface {
    public int getIndex();
    public String getString();
}

/**
 * Helper class for working with IndexingInterface enums
 */
public static class EnumHelper {
    /**
     * Generic method to get enum strings as a list
     */
    public static <T extends IndexingInterface> List<String> getListAsStrings(T[] values) {
        List<String> enumStrings = new ArrayList<>();
        for (T enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }
    
    /**
     * Get list of strings for an enum class that implements IndexingInterface
     */
    public static <T extends Enum<T> & IndexingInterface> List<String> getEnumStrings(Class<T> enumClass) {
        return getListAsStrings(enumClass.getEnumConstants());
    }
}

/**
 * Simple storage for widget settings that converts to/from JSON
 */
class WidgetSettings {
    private String widgetName;
    private HashMap<String, Enum<?>> settings;
    private HashMap<String, Enum<?>> defaults;

    public WidgetSettings(String widgetName) {
        this.widgetName = widgetName;
        this.settings = new HashMap<String, Enum<?>>();
        this.defaults = new HashMap<String, Enum<?>>();
    }

    /**
     * Store a setting using enum class as key
     */
    public <T extends Enum<?>> void set(Class<T> enumClass, T value) {
        settings.put(enumClass.getName(), value);
    }

    /**
     * Store a setting using the enum class and index
     * Useful for setting values from UI components like dropdowns
     * 
     * @param enumClass The enum class to look up values
     * @param index The index of the enum constant to set
     * @return true if successful, false if the index is out of bounds
     */
    public <T extends Enum<?>> boolean setByIndex(Class<T> enumClass, int index) {
        T[] enumConstants = enumClass.getEnumConstants();
        
        // Check if index is valid
        if (index >= 0 && index < enumConstants.length) {
            // Get the enum value at the specified index
            T value = enumConstants[index];
            // Set it using the regular set method
            set(enumClass, value);
            return true;
        }
        
        // Index was out of bounds
        println("Warning: Invalid index " + index + " for enum " + enumClass.getName());
        return false;
    }

    /**
     * Get a setting using enum class as key
     */
    public <T extends Enum<?>> T get(Class<T> enumClass, T defaultValue) {
        String key = enumClass.getName();
        if (settings.containsKey(key)) {
            Object value = settings.get(key);
            if (value != null && enumClass.isInstance(value)) {
                return enumClass.cast(value);
            }
        }
        return defaultValue;
    }

    /**
     * Get a setting using enum class as key (returns null if not found)
     */
    public <T extends Enum<?>> T get(Class<T> enumClass) {
        String key = enumClass.getName();
        if (settings.containsKey(key)) {
            Object value = settings.get(key);
            if (value != null && enumClass.isInstance(value)) {
                return enumClass.cast(value);
            }
        }
        return null;
    }

    /**
     * Save current settings as defaults
     */
    public void saveDefaults() {
        defaults = new HashMap<String, Enum<?>>(settings);
    }

    /**
     * Restore to default settings
     */
    public void restoreDefaults() {
        settings = new HashMap<String, Enum<?>>(defaults);
    }

    /**
     * Convert settings to JSON string
     */
    public String toJSON() {
        JSONObject json = new JSONObject();
        json.setString("widget", widgetName);
        
        JSONArray items = new JSONArray();
        int i = 0;
        
        for (String key : settings.keySet()) {
            Enum<?> value = settings.get(key);
            JSONObject item = new JSONObject();
            item.setString("class", key);
            item.setString("value", value.name());
            items.setJSONObject(i++, item);
        }
        
        json.setJSONArray("settings", items);
        return json.toString();
    }

    /**
     * Load settings from JSON string
     */
    public boolean fromJSON(String jsonString) {
        try {
            JSONObject json = parseJSONObject(jsonString);
            if (json == null) return false;
            
            String loadedWidget = json.getString("widget", "");
            if (!loadedWidget.equals(widgetName)) {
                println("Warning: Widget mismatch. Expected: " + widgetName + ", Found: " + loadedWidget);
            }
            
            JSONArray items = json.getJSONArray("settings");
            if (items != null) {
                for (int i = 0; i < items.size(); i++) {
                    JSONObject item = items.getJSONObject(i);
                    String className = item.getString("class");
                    String valueName = item.getString("value");
                    
                    try {
                        Class<?> enumClass = Class.forName(className);
                        if (enumClass.isEnum()) {
                            @SuppressWarnings("unchecked")
                            Enum<?> enumValue = Enum.valueOf((Class<Enum>)enumClass, valueName);
                            settings.put(className, enumValue);
                        }
                    } catch (Exception e) {
                        println("Error loading setting: " + e.getMessage());
                    }
                }
                return true;
            }
        } catch (Exception e) {
            println("Error parsing JSON: " + e.getMessage());
        }
        return false;
    }
}

/**
 * Example usage
 */
 /*
class ExampleWidgetSettings extends WidgetSettings {
    enum Mode { NORMAL, EXPERT, DEBUG }
    enum Filter { NONE, LOW_PASS, HIGH_PASS, BAND_PASS }
    
    public ExampleWidgetSettings() {
        super("Example");
        
        // Set defaults
        set(Mode.class, Mode.NORMAL);
        set(Filter.class, Filter.NONE);
        saveDefaults();
    }
    
    public void applyToUI() {
        Mode mode = get(Mode.class, Mode.NORMAL);
        Filter filter = get(Filter.class, Filter.NONE);
        
        // Apply to UI controls
        println("Mode: " + mode + ", Filter: " + filter);
    }
    
    public void exampleUsage() {
        // Set some values
        set(Mode.class, Mode.EXPERT);
        set(Filter.class, Filter.BAND_PASS);
        
        // Convert to JSON 
        String json = toJSON();
        println("Settings JSON: " + json);
        
        // Restore defaults 
        restoreDefaults();
        
        // Load from JSON
        fromJSON(json);
    }
}
*/