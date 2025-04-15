//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                       This sketch saves and loads User Settings that appear during Sessions.
//                       -- All Time Series widget settings in Live, Playback, and Synthetic modes
//                       -- All FFT widget settings
//                       -- Default Layout, Board Mode, and other Global Settings
//                       -- Networking Mode and All settings for active networking protocol
//                       -- Accelerometer, Analog Read, Head Plot, Band Power, and Spectrogram
//                       -- Widget/Container Pairs
//                       -- OpenBCI Data Format Settings (.txt and .csv)
//                       Created: Richard Waltman - May/June 2018
//
//    -- Start System first!
//    -- Lowercase 'n' to Save
//    -- Capital 'N' to Load
//    -- Functions saveGUIsettings() and loadGUISettings() are called:
//        - during system initialization between checkpoints 4 and 5
//        - in Interactivty.pde with the rest of the keyboard shortcuts
//        - in TopNav.pde when "Config" --> "Save Settings" || "Load Settings" is clicked
//    -- This allows User to store snapshots of most GUI settings in Users/.../Documents/OpenBCI_GUI/Settings/
//    -- After loading, only a few actions are required: start/stop the data stream and networking streams, open/close serial port
//
//      Tips on adding a new setting:
//      -- figure out if the setting is Global, in an existing widget, or in a new class or widget
//      -- read the comments
//      -- once you find the right place to add your setting, you can copy the surrounding style
//      -- uses JSON keys
//      -- Example2: GUI version and settings version
//      -- Requires new JSON key 'version` and settingsVersion
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class SessionSettings {
    //Current version to save to JSON
    private String settingsVersion = "5.0.0";
    //for screen resizing
    public boolean screenHasBeenResized = false;
    public float timeOfLastScreenResize = 0;
    public int widthOfLastScreen = 0;
    public int heightOfLastScreen = 0;
    //default layout variables
    public int currentLayout;
    //Used to time the GUI intro animation
    public int introAnimationInit = 0;
    public final int INTRO_ANIMATION_DURATION = 2500;

    private final String[] USER_SETTINGS_FILES = {
        "CytonUserSettings.json",
        "DaisyUserSettings.json",
        "GanglionUserSettings.json",
        "PlaybackUserSettings.json",
        "SynthFourUserSettings.json",
        "SynthEightUserSettings.json",
        "SynthSixteenUserSettings.json"
        };
    private final String[] DEFAULT_SETTINGS_FILES = {
        "CytonDefaultSettings.json",
        "DaisyDefaultSettings.json",
        "GanglionDefaultSettings.json",
        "PlaybackDefaultSettings.json",
        "SynthFourDefaultSettings.json",
        "SynthEightDefaultSettings.json",
        "SynthSixteenDefaultSettings.json"
        };

    //Primary JSON objects for saving and loading data
    private JSONObject saveSettingsJSONData;
    private JSONObject loadSettingsJSONData;

    private final String GLOBAL_SETTINGS_KEY = "globalSettings";
    private final String GUI_VERSION_KEY = "guiVersion";
    private final String SESSION_SETTINGS_VERSION_KEY = "sessionSettingsVersion";
    private final String CHANNEL_COUNT_KEY = "channelCount";
    private final String DATA_SOURCE_KEY = "dataSource";
    private final String DATA_SMOOTHING_KEY = "dataSmoothing";
    private final String WIDGET_LAYOUT_KEY = "widgetLayout";
    private final String NETWORKING_KEY = "networking";
    private final String WIDGET_CONTAINER_SETTINGS_KEY = "widgetContainerSettings";
    private final String WIDGET_SETTINGS_KEY = "widgetSettings";

    boolean chanNumError = false;
    boolean dataSourceError = false;

    String saveDialogName; //Used when Save button is pressed
    String loadDialogName; //Used when Load button is pressed
    String controlEventDataSource; //Used for output message on system start
    Boolean errorUserSettingsNotFound = false; //For error catching
    int loadErrorTimerStart;
    int loadErrorTimeWindow = 5000; //Time window in milliseconds to apply channel settings to Cyton board. This is to avoid a GUI crash at ~ 4500-5000 milliseconds.
    Boolean loadErrorCytonEvent = false;
    final int initTimeoutThreshold = 12000; //Timeout threshold in milliseconds

    SessionSettings() {
        //Constructor
    }

    ////////////////////////////////////////////////////////////////
    //               Init GUI Software Settings                   //
    //                                                            //
    //  - Called during system initialization in OpenBCI_GUI.pde  //
    ////////////////////////////////////////////////////////////////
    void init() {
        String defaultSettingsFileToSave = getPath("Default", eegDataSource, globalChannelCount);

        //Take a snapshot of the default GUI settings on every system init
        println("InitSettings: Saving Default Settings to file!");
        try {
            this.save(defaultSettingsFileToSave); //to avoid confusion with save() image
        } catch (Exception e) {
            outputError("Failed to save Default Settings during Init. Please submit an Issue on GitHub.");
            e.printStackTrace();
        }
    }

    ///////////////////////////////
    //      Save GUI Settings    //
    ///////////////////////////////
    void save(String saveGUISettingsFileLocation) {

        // Set up a JSON array
        saveSettingsJSONData = new JSONObject();

        // Global Settings
        JSONObject saveGlobalSettings = new JSONObject();
        saveGlobalSettings.setString(GUI_VERSION_KEY, localGUIVersionString);
        saveGlobalSettings.setString(SESSION_SETTINGS_VERSION_KEY, settingsVersion);
        saveGlobalSettings.setInt(CHANNEL_COUNT_KEY, globalChannelCount);
        saveGlobalSettings.setInt(DATA_SOURCE_KEY, eegDataSource);
        if (currentBoard instanceof SmoothingCapableBoard) {
            saveGlobalSettings.setBoolean(DATA_SMOOTHING_KEY, ((SmoothingCapableBoard)currentBoard).getSmoothingActive());
        }
        saveGlobalSettings.setInt(WIDGET_LAYOUT_KEY, currentLayout);
        saveSettingsJSONData.setJSONObject(GLOBAL_SETTINGS_KEY, saveGlobalSettings);

        // Networking Settings
        JSONObject saveNetworkingSettings = parseJSONObject(dataProcessing.networkingSettings.getJson());
        saveSettingsJSONData.setJSONObject(NETWORKING_KEY, saveNetworkingSettings);

        // Widget layout settings
        JSONObject saveWidgetLayout = new JSONObject();

        int numActiveWidgets = 0;
        //Save what Widgets are active and respective Container number (see Containers.pde)
        for (int i = 0; i < widgetManager.widgets.size(); i++) { //increment through all widgets
            if (widgetManager.widgets.get(i).getIsActive()) { //If a widget is active...
                numActiveWidgets++; //increment numActiveWidgets
                //println("Widget" + i + " is active");
                // activeWidgets.add(i); //keep track of the active widget
                int containerCountsave = widgetManager.widgets.get(i).currentContainer;
                //println("Widget " + i + " is in Container " + containerCountsave);
                saveWidgetLayout.setInt("Widget_"+i, containerCountsave);
            } else if (!widgetManager.widgets.get(i).getIsActive()) { //If a widget is not active...
                saveWidgetLayout.remove("Widget_"+i); //remove non-active widget from JSON
                //println("widget"+i+" is not active");
            }
        }
        println("SessionSettings: " + numActiveWidgets + " active widgets saved!");
        saveSettingsJSONData.setJSONObject(WIDGET_CONTAINER_SETTINGS_KEY, saveWidgetLayout);

        // Settings for all widgets
        JSONObject saveWidgetSettings = parseJSONObject(widgetManager.getWidgetSettingsAsJson());
        saveSettingsJSONData.setJSONObject(WIDGET_SETTINGS_KEY, saveWidgetSettings);

        //Let's save the JSON array to a file!
        saveJSONObject(saveSettingsJSONData, saveGUISettingsFileLocation);

    } 

    void load(String loadGUISettingsFileLocation) throws Exception {
        //Load all saved User Settings from a JSON file if it exists
        loadSettingsJSONData = loadJSONObject(loadGUISettingsFileLocation);

        verbosePrint(loadSettingsJSONData.toString());

        //Check the number of channels saved to json first!
        JSONObject loadGlobalSettings = loadSettingsJSONData.getJSONObject(GLOBAL_SETTINGS_KEY);
        int numChanloaded = loadGlobalSettings.getInt(CHANNEL_COUNT_KEY);
        //Print error if trying to load a different number of channels
        if (numChanloaded != globalChannelCount) {
            println("SessionSettings: Channels being loaded from " + loadGUISettingsFileLocation + " don't match channels being used!");
            chanNumError = true;
            throw new Exception();
        } else {
            chanNumError = false;
        }
        //Check the Data Source integer next: Cyton = 0, Ganglion = 1, Playback = 2, Synthetic = 3
        int loadDatasource = loadGlobalSettings.getInt(DATA_SOURCE_KEY);
        verbosePrint("SessionSettings: Data source loaded: " + loadDatasource + ". Current data source: " + eegDataSource);
        //Print error if trying to load a different data source (ex. Live != Synthetic)
        if (loadDatasource != eegDataSource) {
            println("Data source being loaded from " + loadGUISettingsFileLocation + " doesn't match current data source.");
            dataSourceError = true;
            throw new Exception();
        } else {
            dataSourceError = false;
        }

        if (currentBoard instanceof SmoothingCapableBoard) {
            Boolean loadDataSmoothingSetting = loadGlobalSettings.getBoolean(DATA_SMOOTHING_KEY);
            ((SmoothingCapableBoard)currentBoard).setSmoothingActive(loadDataSmoothingSetting);
            topNav.updateSmoothingButtonText();
        }

        // Layout Settings
        currentLayout = loadGlobalSettings.getInt(WIDGET_LAYOUT_KEY);

        // Networking Settings
        JSONObject networkingSettingsJson = loadSettingsJSONData.getJSONObject(NETWORKING_KEY);
        dataProcessing.networkingSettings.loadJson(networkingSettingsJson.toString());

        // Widget Layout Settings
        JSONObject widgetContainerSettings = loadSettingsJSONData.getJSONObject(WIDGET_CONTAINER_SETTINGS_KEY);
        //Apply Layout directly before loading and applying widgets to containers
        widgetManager.setNewContainerLayout(currentLayout);
        verbosePrint("SessionSettings: Layout " + currentLayout + " Loaded!");
        int numLoadedWidgets = widgetContainerSettings.size();

        //int numActiveWidgets = 0; //reset the counter
        for (int i = 0; i < widgetManager.widgets.size(); i++) { //increment through all widgets
            if (widgetManager.widgets.get(i).getIsActive()) { //If a widget is active...
                widgetManager.widgets.get(i).setIsActive(false);
            }
        }

        //Store the Widget number keys from JSON to a string array
        String[] loadedWidgetsArray = (String[]) widgetContainerSettings.keys().toArray(new String[widgetContainerSettings.size()]);
        //printArray(loadedWidgetsArray);
        int widgetToActivate = 0;
        for (int w = 0; w < numLoadedWidgets; w++) {
            String [] loadWidgetNameNumber = split(loadedWidgetsArray[w], '_');
            //Store the value of the widget to be activated
            widgetToActivate = Integer.valueOf(loadWidgetNameNumber[1]);
            //Load the container for the current widget[w]
            int containerToApply = widgetContainerSettings.getInt(loadedWidgetsArray[w]);

            widgetManager.widgets.get(widgetToActivate).setIsActive(true);//activate the new widget
            widgetManager.widgets.get(widgetToActivate).setContainer(containerToApply);//map it to the container that was loaded!
            println("SessionSettings: Applied Widget " + widgetToActivate + " to Container " + containerToApply);
        }

        JSONObject widgetSettings = loadSettingsJSONData.getJSONObject(WIDGET_SETTINGS_KEY);
        widgetManager.loadWidgetSettingsFromJson(widgetSettings.toString());

        //Load and apply all of the settings that are in dropdown menus. It's a bit much, so it has it's own function below.
        //loadApplyWidgetDropdownText();

        //Apply Time Series Settings Last!!!
        //loadApplyTimeSeriesSettings();
    }

    /**
      * @description Used in TopNav when user clicks ClearSettings->AreYouSure->Yes
      * @params none
      * Output Success message to bottom of GUI when done
      */
    void clearAll() {
        for (File file: new File(directoryManager.getSettingsPath()).listFiles())
            if (!file.isDirectory())
                file.delete();
        controlPanel.recentPlaybackBox.rpb_cp5.get(ScrollableList.class, "recentPlaybackFilesCP").clear();
        controlPanel.recentPlaybackBox.shortFileNames.clear();
        controlPanel.recentPlaybackBox.longFilePaths.clear();
        outputSuccess("All settings have been cleared!");
    }

    /**
      * @description Used in System Init, TopNav, and Interactivity
      * @params mode="User"or"Default", dataSource, and number of channels
      * @returns {String} - filePath or Error if mode not specified correctly
      */
    String getPath(String _mode, int dataSource, int _channelCount) {
        String filePath = directoryManager.getSettingsPath();
        String[] fileNames = new String[7];
        if (_mode.equals("Default")) {
            fileNames = DEFAULT_SETTINGS_FILES;
        } else if (_mode.equals("User")) {
            fileNames = USER_SETTINGS_FILES;
        } else {
            filePath = "Error";
        }
        if (!filePath.equals("Error")) {
            if (dataSource == DATASOURCE_CYTON) {
                filePath += (_channelCount == CYTON_CHANNEL_COUNT) ?
                    fileNames[0] :
                    fileNames[1];
            } else if (dataSource == DATASOURCE_GANGLION) {
                filePath += fileNames[2];
            } else if (dataSource ==  DATASOURCE_PLAYBACKFILE) {
                filePath += fileNames[3];
            } else if (dataSource == DATASOURCE_SYNTHETIC) {
                if (_channelCount == GANGLION_CHANNEL_COUNT) {
                    filePath += fileNames[4];
                } else if (_channelCount == CYTON_CHANNEL_COUNT) {
                    filePath += fileNames[5];
                } else {
                    filePath += fileNames[6];
                }
            }
        }
        return filePath;
    }

    void loadKeyPressed() {
        loadErrorTimerStart = millis();
        String settingsFileToLoad = getPath("User", eegDataSource, globalChannelCount);
        try {
            load(settingsFileToLoad);
            errorUserSettingsNotFound = false;
        } catch (Exception e) {
            //println(e.getMessage());
            e.printStackTrace();
            println(settingsFileToLoad + " not found or other error. Save settings with keyboard 'n' or using dropdown menu.");
            errorUserSettingsNotFound = true;
        }
        //Output message when Loading settings is complete
        String err = null;
        if (chanNumError == false && dataSourceError == false && errorUserSettingsNotFound == false && loadErrorCytonEvent == false) {
            outputSuccess("Settings Loaded!");
        } else if (chanNumError) {
            err = "Invalid number of channels";
        } else if (dataSourceError) {
            err = "Invalid data source";
        } else if (errorUserSettingsNotFound) {
            err = settingsFileToLoad + " not found.";
        }

        //Only try to delete file for SettingsNotFound/Broken settings
        if (err != null && (!chanNumError && !dataSourceError)) {
            println("Load Settings Error: " + err);
            File f = new File(settingsFileToLoad);
            if (f.exists()) {
                if (f.delete()) {
                    outputError("Found old/broken GUI settings. Please reconfigure the GUI and save new settings.");
                } else {
                    outputError("SessionSettings: Error deleting old/broken settings file...");
                }
            }
        }
    }

    void saveButtonPressed() {
        if (saveDialogName == null) {
            File fileToSave = dataFile(sessionSettings.getPath("User", eegDataSource, globalChannelCount));
            FileChooser chooser = new FileChooser(
                    FileChooserMode.SAVE,
                    "saveConfigFile",
                    fileToSave,
                    "Save settings to file");
        } else {
            println("saveSettingsFileName = " + saveDialogName);
            saveDialogName = null;
        }
    }

    void loadButtonPressed() {
        //Select file to load from dialog box
        if (loadDialogName == null) {
            FileChooser chooser = new FileChooser(
                FileChooserMode.LOAD,
                "loadConfigFile",
                new File(directoryManager.getGuiDataPath() + "Settings"),
                "Select a settings file to load");
            saveDialogName = null;
        } else {
            println("loadSettingsFileName = " + loadDialogName);
            loadDialogName = null;
        }
    }

    void defaultButtonPressed() {
        //Revert GUI to default settings that were flashed on system start!
        String defaultSettingsFileToLoad = getPath("Default", eegDataSource, globalChannelCount);
        try {
            //Load all saved User Settings from a JSON file to see if it exists
            JSONObject loadDefaultSettingsJSONData = loadJSONObject(defaultSettingsFileToLoad);
            this.load(defaultSettingsFileToLoad);
            outputSuccess("Default Settings Loaded!");
        } catch (Exception e) {
            outputError("Default Settings Error: Valid Default Settings will be saved next system start.");
            File f = new File(defaultSettingsFileToLoad);
            if (f.exists()) {
                if (f.delete()) {
                    println("SessionSettings: Old/Broken Default Settings file succesfully deleted.");
                } else {
                    println("SessionSettings: Error deleting Default Settings file...");
                }
            }
        }
    }

    public void autoLoadSessionSettings() {
        loadKeyPressed();
    }

}

//////////////////////////////////////////
//  Global Functions                    //
// Called by Buttons with the same name //
//////////////////////////////////////////
// Select file to save custom settings using dropdown in TopNav.pde
void saveConfigFile(File selection) {
    if (selection == null) {
        println("SessionSettings: saveConfigFile: Window was closed or the user hit cancel.");
    } else {
        println("SessionSettings: saveConfigFile: User selected " + selection.getAbsolutePath());
        sessionSettings.saveDialogName = selection.getAbsolutePath();
        sessionSettings.save(sessionSettings.saveDialogName); //save current settings to JSON file in SavedData
        outputSuccess("Settings Saved! Using Expert Mode, you can load these settings using 'N' key. Click \"Default\" to revert to factory settings."); //print success message to screen
        sessionSettings.saveDialogName = null; //reset this variable for future use
    }
}
// Select file to load custom settings using dropdown in TopNav.pde
void loadConfigFile(File selection) {
    if (selection == null) {
        println("SessionSettings: loadConfigFile: Window was closed or the user hit cancel.");
    } else {
        println("SessionSettings: loadConfigFile: User selected " + selection.getAbsolutePath());
        //output("You have selected \"" + selection.getAbsolutePath() + "\" to Load custom settings.");
        sessionSettings.loadDialogName = selection.getAbsolutePath();
        try {
            sessionSettings.load(sessionSettings.loadDialogName); //load settings from JSON file in /data/
            //Output success message when Loading settings is complete without errors
            if (sessionSettings.chanNumError == false
                && sessionSettings.dataSourceError == false
                && sessionSettings.loadErrorCytonEvent == false) {
                    outputSuccess("Settings Loaded!");
                }
        } catch (Exception e) {
            println("SessionSettings: Incompatible settings file or other error");
            if (sessionSettings.chanNumError == true) {
                outputError("Settings Error:  Channel Number Mismatch Detected");
            } else if (sessionSettings.dataSourceError == true) {
                outputError("Settings Error: Data Source Mismatch Detected");
            } else {
                outputError("Error trying to load settings file, possibly from previous GUI. Removing old settings.");
                if (selection.exists()) selection.delete();
            }
        }
        sessionSettings.loadDialogName = null; //reset this variable for future use
    }
}