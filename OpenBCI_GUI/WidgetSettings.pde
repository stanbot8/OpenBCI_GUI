class WidgetSettings { 
    // A map to store settings with string keys and enum values
    protected HashMap<String, Enum<?>> settings = new HashMap<String, Enum<?>>();
    // Widget identifier for saving/loading specific widget settings
    private String titleString;

    public WidgetSettings(String titleString) {
        this.titleString = titleString;
    }

    // Store a setting with a key and enum value
    public <T extends Enum<?>> void setSetting(String key, T value) {
        settings.put(key, value);
    }

    // Retrieve a setting by key, with optional default value
    public <T extends Enum<?>> T getSetting(String key, T defaultValue) {
        if (settings.containsKey(key) && settings.get(key).getClass() == defaultValue.getClass()) {
            return (T) settings.get(key);
        }
        return defaultValue;
    }

    /**
     * Converts settings to a JSON string
     * @return JSON string representation of the settings
     */
    public String getJSON() {
        try {
            // Create a wrapper JSON object that contains metadata and settings
            JSONObject jsonData = new JSONObject();
            jsonData.setString("titleString", titleString);
            
            // Create settings JSON object
            JSONObject settingsJson = new JSONObject();
            
            // Add each setting to the JSON object with its class and value for proper deserialization
            for (Map.Entry<String, Enum<?>> entry : settings.entrySet()) {
                JSONObject enumValue = new JSONObject();
                Enum<?> value = entry.getValue();
                enumValue.setString("enumClass", value.getClass().getName());
                enumValue.setString("enumValue", value.name());
                settingsJson.setJSONObject(entry.getKey(), enumValue);
            }
            
            jsonData.setJSONObject("settings", settingsJson);
            return jsonData.toString();
        } catch (Exception e) {
            println("Error converting settings to JSON: " + e.getMessage());
            e.printStackTrace();
            return "{}";
        }
    }

    /**
     * Loads settings from a JSON string
     * @param jsonString JSON string to load settings from
     * @return true if successful, false otherwise
     */
    public boolean loadJSON(String jsonString) {
        try {
            // Parse the JSON string
            JSONObject jsonData = parseJSONObject(jsonString);
            if (jsonData == null) {
                println("Invalid JSON string");
                return false;
            }

            // Verify widget name
            String loadedTitleString = jsonData.getString("titleString", "");
            if (!loadedTitleString.equals(titleString)) {
                println("Warning: Widget name mismatch. Expected: " + titleString + ", Found: " + loadedTitleString);
                // Continuing anyway, might be a compatible widget
            }
            
            // Clear existing settings
            settings.clear();
            
            // Load settings
            JSONObject settingsJson = jsonData.getJSONObject("settings");
            if (settingsJson == null) {
                println("No settings found in JSON");
                return false;
            }
            
            // Loop through each setting in the JSON
            for (Object key : settingsJson.keys()) {
                String settingKey = (String)key;
                JSONObject enumData = settingsJson.getJSONObject(settingKey);
                
                String enumClassName = enumData.getString("enumClass", "");
                String enumValueName = enumData.getString("enumValue", "");
                
                // Skip if missing required data
                if (enumClassName.isEmpty() || enumValueName.isEmpty()) {
                    continue;
                }
                
                try {
                    // Load the enum class
                    Class<?> enumClass = Class.forName(enumClassName);
                    if (!enumClass.isEnum()) {
                        println("Class " + enumClassName + " is not an enum");
                        continue;
                    }
                    
                    // Get the enum value
                    @SuppressWarnings("unchecked")
                    Enum<?> enumValue = Enum.valueOf((Class<Enum>)enumClass, enumValueName);
                    settings.put(settingKey, enumValue);
                } catch (ClassNotFoundException e) {
                    println("Enum class not found: " + enumClassName);
                } catch (IllegalArgumentException e) {
                    println("Enum value not found: " + enumValueName);
                } catch (Exception e) {
                    println("Error loading enum: " + e.getMessage());
                }
            }
            
            return true;
        } catch (Exception e) {
            println("Error loading settings from JSON: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    // Apply settings to UI components
    public void applySettingsToCp5(ControlP5 cp5) {
        // This is a default implementation
        // Widget-specific classes should override this method
    }
}

// Example extension of WidgetSettings for a specific widget
class ExampleWidgetSettings extends WidgetSettings {
    public ExampleWidgetSettings() {
        super("ExampleWidget");
    }
    
    // Override to implement specific UI binding
    @Override
    public void applySettingsToCp5(ControlP5 cp5) {
        // Example: Apply dropdown settings
        for (String key : settings.keySet()) {
            Enum<?> value = settings.get(key);
            
            if (value instanceof IndexingInterface) {
                IndexingInterface enumValue = (IndexingInterface)value;
                ScrollableList dropdown = (ScrollableList)cp5.getController(key);
                if (dropdown != null) {
                    dropdown.setValue(enumValue.getIndex());
                }
            }
            
            // Handle other control types as needed
            // Toggle, RadioButton, Slider, etc.
        }
    }
    
    // Additional methods specific to this widget
    public void setupDefaultSettings() {
        // Set default values for this widget
        // Example: setSetting("mode", SomeEnum.DEFAULT_MODE);
    }
}