//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
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
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////
//   SessionSettings Class    //
/////////////////////////////////
class SessionSettings {
    //Current version to save to JSON
    String settingsVersion = "4.0.0";
    //for screen resizing
    boolean screenHasBeenResized = false;
    float timeOfLastScreenResize = 0;
    int widthOfLastScreen = 0;
    int heightOfLastScreen = 0;
    //default layout variables
    int currentLayout;
    //Used to time the GUI intro animation
    int introAnimationInit = 0;
    final int introAnimationDuration = 2500;
    //Max File Size #461, default option 4 -> 60 minutes
    public final String[] fileDurations = {"5 Minutes", "15 minutes", "30 Minutes", "60 Minutes", "120 Minutes", "No Limit"};
    public final int[] fileDurationInts = {5, 15, 30, 60, 120, -1};
    public final int defaultOBCIMaxFileSize = 3; //4th option from the above list
    private boolean logFileIsOpen = false;
    private long logFileStartTime;
    private long logFileMaxDurationNano = -1;
    //this is a global CColor that determines the style of all widget dropdowns ... this should go in WidgetManager.pde
    CColor dropdownColors = new CColor();

    //default configuration settings file location and file name variables
    private String sessionPath = "";
    final String[] userSettingsFiles = {
        "CytonUserSettings.json",
        "DaisyUserSettings.json",
        "GanglionUserSettings.json",
        "PlaybackUserSettings.json",
        "SynthFourUserSettings.json",
        "SynthEightUserSettings.json",
        "SynthSixteenUserSettings.json"
        };
    final String[] defaultSettingsFiles = {
        "CytonDefaultSettings.json",
        "DaisyDefaultSettings.json",
        "GanglionDefaultSettings.json",
        "PlaybackDefaultSettings.json",
        "SynthFourDefaultSettings.json",
        "SynthEightDefaultSettings.json",
        "SynthSixteenDefaultSettings.json"
        };

    //Load Accel. dropdown variables
    int loadAccelVertScale;
    int loadAccelHorizScale;

    //Load Analog Read dropdown variables
    int loadAnalogReadVertScale;
    int loadAnalogReadHorizScale;

    //Load FFT dropdown variables
    int fftMaxFrqLoad;
    int fftMaxuVLoad;
    int fftLogLinLoad;
    int fftSmoothingLoad;
    int fftFilterLoad;

    //Load Headplot dropdown variables
    int hpIntensityLoad;
    int hpPolarityLoad;
    int hpContoursLoad;
    int hpSmoothingLoad;

    //Band Power widget settings
    //smoothing and filter dropdowns are linked to FFT, so no need to save again
    List<Integer> loadBPActiveChans = new ArrayList<Integer>();
    int loadBPAutoClean;
    int loadBPAutoCleanThreshold;
    int loadBPAutoCleanTimer;

    //Spectrogram widget settings
    List<Integer> loadSpectActiveChanTop = new ArrayList<Integer>();
    List<Integer> loadSpectActiveChanBot = new ArrayList<Integer>();
    int spectMaxFrqLoad;
    int spectSampleRateLoad;
    int spectLogLinLoad;

    //Networking Settings save/load variables
    JSONObject loadNetworkingSettings;

    //EMG Widget
    List<Integer> loadEmgActiveChannels = new ArrayList<Integer>();

    //EMG Joystick Widget
    int loadEmgJoystickSmoothing;
    List<Integer> loadEmgJoystickInputs = new ArrayList<Integer>();

    //Marker Widget
    private int loadMarkerWindow;
    private int loadMarkerVertScale;

    //Focus Widget
    private int loadFocusMetric;
    private int loadFocusThreshold;
    private int loadFocusWindow;

    //Primary JSON objects for saving and loading data
    private JSONObject saveSettingsJSONData;
    private JSONObject loadSettingsJSONData;

    private final String kJSONKeyDataInfo = "dataInfo";
    private final String kJSONKeyTimeSeries = "timeSeries";
    private final String kJSONKeySettings = "settings";
    private final String kJSONKeyFFT = "fft";
    private final String kJSONKeyAccel = "accelerometer";
    private final String kJSONKeyNetworking = "networking";
    private final String kJSONKeyHeadplot = "headplot";
    private final String kJSONKeyBandPower = "bandPower";
    private final String kJSONKeyWidget = "widget";
    private final String kJSONKeyVersion = "version";
    private final String kJSONKeySpectrogram = "spectrogram";
    private final String kJSONKeyEmg = "emg";
    private final String kJSONKeyEmgJoystick = "emgJoystick";
    private final String kJSONKeyMarker = "marker";
    private final String kJSONKeyFocus = "focus";

    //used only in this class to count the number of channels being used while saving/loading, this gets updated in updateGlobalChannelCount whenever the number of channels being used changes
    int sessionSettingsChannelCount;
    int numChanloaded;
    boolean chanNumError = false;
    int numLoadedWidgets;
    String [] loadedWidgetsArray;
    int loadFramerate;
    int loadDatasource;
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
        //Instantiated on app start in OpenBCI_GUI.pde
        dropdownColors.setActive((int)BUTTON_PRESSED); //bg color of box when pressed
        dropdownColors.setForeground((int)BUTTON_HOVER); //when hovering over any box (primary or dropdown)
        dropdownColors.setBackground((int)color(255)); //bg color of boxes (including primary)
        dropdownColors.setCaptionLabel((int)color(1, 18, 41)); //color of text in primary box
        // dropdownColors.setValueLabel((int)color(1, 18, 41)); //color of text in all dropdown boxes
        dropdownColors.setValueLabel((int)color(100)); //color of text in all dropdown boxes

        setLogFileDurationChoice(defaultOBCIMaxFileSize);
    }

    ///////////////////////////////////
    // OpenBCI Data Format Functions //
    ///////////////////////////////////

    public void setLogFileIsOpen (boolean _toggle) {
        logFileIsOpen = _toggle;
    }

    public boolean isLogFileOpen() {
        return logFileIsOpen;
    }

    public void setLogFileStartTime(long _time) {
        logFileStartTime = _time;
        verbosePrint("Settings: LogFileStartTime = " + _time);
    }

    public void setLogFileDurationChoice(int choice) {
        logFileMaxDurationNano = fileDurationInts[choice] * 1000000000L * 60;
        println("Settings: LogFileMaxDuration = " + fileDurationInts[choice] + " minutes");
    }

    //Only called during live mode && using OpenBCI Data Format
    public boolean maxLogTimeReached() {
        if (logFileMaxDurationNano < 0) {
            return false;
        } else {
            return (System.nanoTime() - logFileStartTime) > (logFileMaxDurationNano);
        }
    }

    public void setSessionPath (String _path) {
        sessionPath = _path;
    }

    public String getSessionPath() {
        //println("SESSIONPATH==",sessionPath, millis());
        return sessionPath;
    }

    ////////////////////////////////////////////////////////////////
    //               Init GUI Software Settings                   //
    //                                                            //
    //  - Called during system initialization in OpenBCI_GUI.pde  //
    ////////////////////////////////////////////////////////////////
    void init() {
        String defaultSettingsFileToSave = getPath("Default", eegDataSource, globalChannelCount);
        int defaultNumChanLoaded = 0;
        int defaultLoadedDataSource = 0;
        String defaultSettingsVersion = "";
        String defaultGUIVersion = "";

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

        //Set up a JSON array
        saveSettingsJSONData = new JSONObject();

        //Save the number of channels being used and eegDataSource in the first object
        JSONObject saveNumChannelsData = new JSONObject();
        saveNumChannelsData.setInt("Channels", sessionSettingsChannelCount);
        saveNumChannelsData.setInt("Data Source", eegDataSource);
        //println("Settings: NumChan: " + sessionSettingsChannelCount);
        saveSettingsJSONData.setJSONObject(kJSONKeyDataInfo, saveNumChannelsData);

        //Make a new JSON Object for Time Series Settings
        JSONObject saveTSSettings = new JSONObject();
        saveTSSettings.setInt("Time Series Vert Scale", w_timeSeries.getVerticalScale().getIndex());
        saveTSSettings.setInt("Time Series Horiz Scale", w_timeSeries.getHorizontalScale().getIndex());
        saveTSSettings.setInt("Time Series Label Mode", w_timeSeries.getLabelMode().getIndex());
        //Save data from the Active channel checkBoxes
        JSONArray saveActiveChanTS = new JSONArray();
        int numActiveTSChan = w_timeSeries.tsChanSelect.getActiveChannels().size();
        for (int i = 0; i < numActiveTSChan; i++) {
            int activeChannel = w_timeSeries.tsChanSelect.getActiveChannels().get(i);
            saveActiveChanTS.setInt(i, activeChannel);
        }
        saveTSSettings.setJSONArray("activeChannels", saveActiveChanTS);
        saveSettingsJSONData.setJSONObject(kJSONKeyTimeSeries, saveTSSettings);

        //Make a second JSON object within our JSONArray to store Global settings for the GUI
        JSONObject saveGlobalSettings = new JSONObject();
        saveGlobalSettings.setInt("Current Layout", currentLayout);
        //FIX ME
        /*
        saveGlobalSettings.setInt("Analog Read Vert Scale", arVertScaleSave);
        saveGlobalSettings.setInt("Analog Read Horiz Scale", arHorizScaleSave);
        */
        if (currentBoard instanceof SmoothingCapableBoard) {
            saveGlobalSettings.setBoolean("Data Smoothing", ((SmoothingCapableBoard)currentBoard).getSmoothingActive());
        }
        saveSettingsJSONData.setJSONObject(kJSONKeySettings, saveGlobalSettings);

        /////Setup JSON Object for gui version and settings Version
        JSONObject saveVersionInfo = new JSONObject();
        saveVersionInfo.setString("gui", localGUIVersionString);
        saveVersionInfo.setString("settings", settingsVersion);
        saveSettingsJSONData.setJSONObject(kJSONKeyVersion, saveVersionInfo);

        ///////////////////////////////////////////////Setup new JSON object to save FFT settings
        JSONObject saveFFTSettings = new JSONObject();

        //FIX ME
        /*
        //Save FFT_Max Freq Setting. The max frq variable is updated every time the user selects a dropdown in the FFT widget
        saveFFTSettings.setInt("FFT_Max Freq", fftMaxFrqSave);
        //Save FFT_Max uV Setting. The max uV variable is updated also when user selects dropdown in the FFT widget
        saveFFTSettings.setInt("FFT_Max uV", fftMaxuVSave);
        //Save FFT_LogLin Setting. Same thing happens for LogLin
        saveFFTSettings.setInt("FFT_LogLin", fftLogLinSave);
        //Save FFT_Smoothing Setting
        saveFFTSettings.setInt("FFT_Smoothing", fftSmoothingSave);
        //Save FFT_Filter Setting
        if (isFFTFiltered == true)  fftFilterSave = 0;
        if (isFFTFiltered == false)  fftFilterSave = 1;
        saveFFTSettings.setInt("FFT_Filter",  fftFilterSave);
        */
        //Set the FFT JSON Object
        saveSettingsJSONData.setJSONObject(kJSONKeyFFT, saveFFTSettings); //next object will be set to sessionSettingsChannelCount+3, etc.

        ///////////////////////////////////////////////Setup new JSON object to save Accelerometer settings
        //FIX ME
        /*
        if (w_accelerometer != null) {
            JSONObject saveAccSettings = new JSONObject();
            saveAccSettings.setInt("Accelerometer Vert Scale", accVertScaleSave);
            saveAccSettings.setInt("Accelerometer Horiz Scale", accHorizScaleSave);
            saveSettingsJSONData.setJSONObject(kJSONKeyAccel, saveAccSettings);
        }
        */

        ///////////////////////////////////////////////Save Networking settings
        String nwSettingsValues = dataProcessing.networkingSettings.getJson();
        JSONObject saveNetworkingSettings = parseJSONObject(nwSettingsValues);
        saveSettingsJSONData.setJSONObject(kJSONKeyNetworking, saveNetworkingSettings);

        ///////////////////////////////////////////////Setup new JSON object to save Headplot settings
        if (w_headPlot != null) {
            JSONObject saveHeadplotSettings = new JSONObject();

            //FIX ME
            /*
            //Save Headplot Intesity
            saveHeadplotSettings.setInt("HP_intensity", hpIntensitySave);
            //Save Headplot Polarity
            saveHeadplotSettings.setInt("HP_polarity", hpPolaritySave);
            //Save Headplot contours
            saveHeadplotSettings.setInt("HP_contours", hpContoursSave);
            //Save Headplot Smoothing Setting
            saveHeadplotSettings.setInt("HP_smoothing", hpSmoothingSave);
            //Set the Headplot JSON Object
            */
            saveSettingsJSONData.setJSONObject(kJSONKeyHeadplot, saveHeadplotSettings);
        }

        ///////////////////////////////////////////////Setup new JSON object to save Band Power settings
        JSONObject saveBPSettings = new JSONObject();
        
        /*
        //FIX ME
        //Save data from the Active channel checkBoxes
        JSONArray saveActiveChanBP = new JSONArray();
        int numActiveBPChan = w_bandPower.bpChanSelect.getActiveChannels().size();
        for (int i = 0; i < numActiveBPChan; i++) {
            int activeChannel = w_bandPower.bpChanSelect.getActiveChannels().get(i);
            saveActiveChanBP.setInt(i, activeChannel);
        }
        saveBPSettings.setJSONArray("activeChannels", saveActiveChanBP);
        saveBPSettings.setInt("bpAutoClean", w_bandPower.getAutoClean().getIndex());
        saveBPSettings.setInt("bpAutoCleanThreshold", w_bandPower.getAutoCleanThreshold().getIndex());
        saveBPSettings.setInt("bpAutoCleanTimer", w_bandPower.getAutoCleanTimer().getIndex());
        */
        saveSettingsJSONData.setJSONObject(kJSONKeyBandPower, saveBPSettings);

        ///////////////////////////////////////////////Setup new JSON object to save Spectrogram settings
        JSONObject saveSpectrogramSettings = new JSONObject();
        //Save data from the Active channel checkBoxes - Top
        JSONArray saveActiveChanSpectTop = new JSONArray();
        int numActiveSpectChanTop = w_spectrogram.spectChanSelectTop.getActiveChannels().size();
        for (int i = 0; i < numActiveSpectChanTop; i++) {
            int activeChannel = w_spectrogram.spectChanSelectTop.getActiveChannels().get(i);
            saveActiveChanSpectTop.setInt(i, activeChannel);
        }
        saveSpectrogramSettings.setJSONArray("activeChannelsTop", saveActiveChanSpectTop);
        //Save data from the Active channel checkBoxes - Bottom
        JSONArray saveActiveChanSpectBot = new JSONArray();
        int numActiveSpectChanBot = w_spectrogram.spectChanSelectBot.getActiveChannels().size();
        for (int i = 0; i < numActiveSpectChanBot; i++) {
            int activeChannel = w_spectrogram.spectChanSelectBot.getActiveChannels().get(i);
            saveActiveChanSpectBot.setInt(i, activeChannel);
        }
        saveSpectrogramSettings.setJSONArray("activeChannelsBot", saveActiveChanSpectBot);
        //Save Spectrogram_Max Freq Setting. The max frq variable is updated every time the user selects a dropdown in the spectrogram widget
        //FIX ME
        /*
        saveSpectrogramSettings.setInt("Spectrogram_Max Freq", spectMaxFrqSave);
        saveSpectrogramSettings.setInt("Spectrogram_Sample Rate", spectSampleRateSave);
        saveSpectrogramSettings.setInt("Spectrogram_LogLin", spectLogLinSave);
        */
        saveSettingsJSONData.setJSONObject(kJSONKeySpectrogram, saveSpectrogramSettings);

        ///////////////////////////////////////////////Setup new JSON object to save EMG Settings
        JSONObject saveEMGSettings = new JSONObject();

        //Save data from the Active channel checkBoxes
        JSONArray saveActiveChanEMG = new JSONArray();
        int numActiveEMGChan = w_emg.emgChannelSelect.getActiveChannels().size();
        for (int i = 0; i < numActiveEMGChan; i++) {
            int activeChannel = w_emg.emgChannelSelect.getActiveChannels().get(i);
            saveActiveChanEMG.setInt(i, activeChannel);
        }
        saveEMGSettings.setJSONArray("activeChannels", saveActiveChanEMG);
        saveSettingsJSONData.setJSONObject(kJSONKeyEmg, saveEMGSettings);

        ///////////////////////////////////////////////Setup new JSON object to save EMG Joystick Settings
        JSONObject saveEmgJoystickSettings = new JSONObject();
        saveEmgJoystickSettings.setInt("smoothing", w_emgJoystick.joystickSmoothing.getIndex());
        JSONArray saveEmgJoystickInputs = new JSONArray();
        for (int i = 0; i < w_emgJoystick.getNumEMGInputs(); i++) {
            saveEmgJoystickInputs.setInt(i, w_emgJoystick.emgJoystickInputs.getInput(i).getIndex());
        }
        saveEmgJoystickSettings.setJSONArray("joystickInputs", saveEmgJoystickInputs);
        saveSettingsJSONData.setJSONObject(kJSONKeyEmgJoystick, saveEmgJoystickSettings);

        ///////////////////////////////////////////////Setup new JSON object to save Marker Widget Settings
        JSONObject saveMarkerSettings = new JSONObject();
        saveMarkerSettings.setInt("markerWindow", w_marker.getMarkerWindow().getIndex());
        saveMarkerSettings.setInt("markerVertScale", w_marker.getMarkerVertScale().getIndex());
        saveSettingsJSONData.setJSONObject(kJSONKeyMarker, saveMarkerSettings);

        ///////////////////////////////////////////////Setup new JSON object to save Marker Widget Settings
        JSONObject saveFocusSettings = new JSONObject();
        saveFocusSettings.setInt("focusMetric", w_focus.getFocusMetric().getIndex());
        saveFocusSettings.setInt("focusThreshold", w_focus.getFocusThreshold().getIndex());
        saveFocusSettings.setInt("focusWindow", w_focus.getFocusWindow().getIndex());
        saveSettingsJSONData.setJSONObject(kJSONKeyFocus, saveFocusSettings);

        ///////////////////////////////////////////////Setup new JSON object to save Widgets Active in respective Containers
        JSONObject saveWidgetSettings = new JSONObject();

        int numActiveWidgets = 0;
        //Save what Widgets are active and respective Container number (see Containers.pde)
        for (int i = 0; i < wm.widgets.size(); i++) { //increment through all widgets
            if (wm.widgets.get(i).getIsActive()) { //If a widget is active...
                numActiveWidgets++; //increment numActiveWidgets
                //println("Widget" + i + " is active");
                // activeWidgets.add(i); //keep track of the active widget
                int containerCountsave = wm.widgets.get(i).currentContainer;
                //println("Widget " + i + " is in Container " + containerCountsave);
                saveWidgetSettings.setInt("Widget_"+i, containerCountsave);
            } else if (!wm.widgets.get(i).getIsActive()) { //If a widget is not active...
                saveWidgetSettings.remove("Widget_"+i); //remove non-active widget from JSON
                //println("widget"+i+" is not active");
            }
        }
        println("SessionSettings: " + numActiveWidgets + " active widgets saved!");
        //Print what widgets are in the containers used by current layout for only the number of active widgets
        //for (int i = 0; i < numActiveWidgets; i++) {
            //int containerCounter = wm.layouts.get(currentLayout).containerInts[i];
            //println("Container " + containerCounter + " is available"); //For debugging
        //}
        saveSettingsJSONData.setJSONObject(kJSONKeyWidget, saveWidgetSettings);

        /////////////////////////////////////////////////////////////////////////////////
        ///ADD more global settings above this line in the same formats as above/////////

        //Let's save the JSON array to a file!
        saveJSONObject(saveSettingsJSONData, saveGUISettingsFileLocation);

    }  //End of Save GUI Settings function

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                Load GUI Settings                                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    void load(String loadGUISettingsFileLocation) throws Exception {
        //Load all saved User Settings from a JSON file if it exists
        loadSettingsJSONData = loadJSONObject(loadGUISettingsFileLocation);

        verbosePrint(loadSettingsJSONData.toString());

        //Check the number of channels saved to json first!
        JSONObject loadDataSettings = loadSettingsJSONData.getJSONObject(kJSONKeyDataInfo);
        numChanloaded = loadDataSettings.getInt("Channels");
        //Print error if trying to load a different number of channels
        if (numChanloaded != sessionSettingsChannelCount) {
            println("Channels being loaded from " + loadGUISettingsFileLocation + " don't match channels being used!");
            chanNumError = true;
            throw new Exception();
        } else {
            chanNumError = false;
        }
        //Check the Data Source integer next: Cyton = 0, Ganglion = 1, Playback = 2, Synthetic = 3
        loadDatasource = loadDataSettings.getInt("Data Source");
        verbosePrint("loadGUISettings: Data source loaded: " + loadDatasource + ". Current data source: " + eegDataSource);
        //Print error if trying to load a different data source (ex. Live != Synthetic)
        if (loadDatasource != eegDataSource) {
            println("Data source being loaded from " + loadGUISettingsFileLocation + " doesn't match current data source.");
            dataSourceError = true;
            throw new Exception();
        } else {
            dataSourceError = false;
        }

        //get the global settings JSON object
        JSONObject loadGlobalSettings = loadSettingsJSONData.getJSONObject(kJSONKeySettings);
        //Store loaded layout to current layout variable
        currentLayout = loadGlobalSettings.getInt("Current Layout");
        //FIX ME
        /*
        loadAnalogReadVertScale = loadGlobalSettings.getInt("Analog Read Vert Scale");
        loadAnalogReadHorizScale = loadGlobalSettings.getInt("Analog Read Horiz Scale");
        */
        //Load more global settings after this line, if needed
        Boolean loadDataSmoothingSetting = (currentBoard instanceof SmoothingCapableBoard) ? loadGlobalSettings.getBoolean("Data Smoothing") : null;

        //get the FFT settings
        //FIX ME
        /*
        JSONObject loadFFTSettings = loadSettingsJSONData.getJSONObject(kJSONKeyFFT);
        fftMaxFrqLoad = loadFFTSettings.getInt("FFT_Max Freq");
        fftMaxuVLoad = loadFFTSettings.getInt("FFT_Max uV");
        fftLogLinLoad = loadFFTSettings.getInt("FFT_LogLin");
        fftSmoothingLoad = loadFFTSettings.getInt("FFT_Smoothing");
        fftFilterLoad = loadFFTSettings.getInt("FFT_Filter");
        */

        //FIX ME
        /*
        //get the Accelerometer settings
        if (w_accelerometer != null) {
            JSONObject loadAccSettings = loadSettingsJSONData.getJSONObject(kJSONKeyAccel);
            loadAccelVertScale = loadAccSettings.getInt("Accelerometer Vert Scale");
            loadAccelHorizScale = loadAccSettings.getInt("Accelerometer Horiz Scale");
        }
        */

        //get the Networking Settings
        loadNetworkingSettings = loadSettingsJSONData.getJSONObject(kJSONKeyNetworking);

        //get the  Headplot settings
        if (w_headPlot != null) {
            //FIX ME
            /*
            JSONObject loadHeadplotSettings = loadSettingsJSONData.getJSONObject(kJSONKeyHeadplot);
            hpIntensityLoad = loadHeadplotSettings.getInt("HP_intensity");
            hpPolarityLoad = loadHeadplotSettings.getInt("HP_polarity");
            hpContoursLoad = loadHeadplotSettings.getInt("HP_contours");
            hpSmoothingLoad = loadHeadplotSettings.getInt("HP_smoothing");
            */
        }

        //Get Band Power widget settings
        //FIX ME
        /*
        loadBPActiveChans.clear();
        JSONObject loadBPSettings = loadSettingsJSONData.getJSONObject(kJSONKeyBandPower);
        JSONArray loadBPChan = loadBPSettings.getJSONArray("activeChannels");
        for (int i = 0; i < loadBPChan.size(); i++) {
            loadBPActiveChans.add(loadBPChan.getInt(i));
        }
        loadBPAutoClean = loadBPSettings.getInt("bpAutoClean");
        loadBPAutoCleanThreshold = loadBPSettings.getInt("bpAutoCleanThreshold");
        loadBPAutoCleanTimer = loadBPSettings.getInt("bpAutoCleanTimer");
        //println("Settings: band power active chans loaded = " + loadBPActiveChans );
        */

        try {
            //Get Spectrogram widget settings
            loadSpectActiveChanTop.clear();
            loadSpectActiveChanBot.clear();
            JSONObject loadSpectSettings = loadSettingsJSONData.getJSONObject(kJSONKeySpectrogram);
            JSONArray loadSpectChanTop = loadSpectSettings.getJSONArray("activeChannelsTop");
            for (int i = 0; i < loadSpectChanTop.size(); i++) {
                loadSpectActiveChanTop.add(loadSpectChanTop.getInt(i));
            }
            JSONArray loadSpectChanBot = loadSpectSettings.getJSONArray("activeChannelsBot");
            for (int i = 0; i < loadSpectChanBot.size(); i++) {
                loadSpectActiveChanBot.add(loadSpectChanBot.getInt(i));
            }
            spectMaxFrqLoad = loadSpectSettings.getInt("Spectrogram_Max Freq");
            spectSampleRateLoad = loadSpectSettings.getInt("Spectrogram_Sample Rate");
            spectLogLinLoad = loadSpectSettings.getInt("Spectrogram_LogLin");
            //println(loadSpectActiveChanTop, loadSpectActiveChanBot);
        } catch (Exception e) {
            e.printStackTrace();
        }

        //Get EMG widget settings
        loadEmgActiveChannels.clear();
        JSONObject loadEmgSettings = loadSettingsJSONData.getJSONObject(kJSONKeyEmg);
        JSONArray loadEmgChan = loadEmgSettings.getJSONArray("activeChannels");
        for (int i = 0; i < loadEmgChan.size(); i++) {
            loadEmgActiveChannels.add(loadEmgChan.getInt(i));
        }

        //Get EMG Joystick widget settings
        JSONObject loadEmgJoystickSettings = loadSettingsJSONData.getJSONObject(kJSONKeyEmgJoystick);
        loadEmgJoystickSmoothing = loadEmgJoystickSettings.getInt("smoothing");
        loadEmgJoystickInputs.clear();
        JSONArray loadJoystickInputsJson = loadEmgJoystickSettings.getJSONArray("joystickInputs");
        for (int i = 0; i < loadJoystickInputsJson.size(); i++) {
            loadEmgJoystickInputs.add(loadJoystickInputsJson.getInt(i));
        }

        //Get Marker widget settings
        JSONObject loadMarkerSettings = loadSettingsJSONData.getJSONObject(kJSONKeyMarker);
        loadMarkerWindow = loadMarkerSettings.getInt("markerWindow");
        loadMarkerVertScale = loadMarkerSettings.getInt("markerVertScale");

        //Get Focus widget settings
        JSONObject loadFocusSettings = loadSettingsJSONData.getJSONObject(kJSONKeyFocus);
        loadFocusMetric = loadFocusSettings.getInt("focusMetric");
        loadFocusThreshold = loadFocusSettings.getInt("focusThreshold");
        loadFocusWindow = loadFocusSettings.getInt("focusWindow");

        //get the  Widget/Container settings
        JSONObject loadWidgetSettings = loadSettingsJSONData.getJSONObject(kJSONKeyWidget);
        //Apply Layout directly before loading and applying widgets to containers
        wm.setNewContainerLayout(currentLayout);
        verbosePrint("LoadGUISettings: Layout " + currentLayout + " Loaded!");
        numLoadedWidgets = loadWidgetSettings.size();


        //int numActiveWidgets = 0; //reset the counter
        for (int w = 0; w < wm.widgets.size(); w++) { //increment through all widgets
            if (wm.widgets.get(w).getIsActive()) { //If a widget is active...
                verbosePrint("Deactivating widget [" + w + "]");
                wm.widgets.get(w).setIsActive(false);
                //numActiveWidgets++; //counter the number of de-activated widgets
            }
        }

        //Store the Widget number keys from JSON to a string array
        loadedWidgetsArray = (String[]) loadWidgetSettings.keys().toArray(new String[loadWidgetSettings.size()]);
        //printArray(loadedWidgetsArray);
        int widgetToActivate = 0;
        for (int w = 0; w < numLoadedWidgets; w++) {
                String [] loadWidgetNameNumber = split(loadedWidgetsArray[w], '_');
                //Store the value of the widget to be activated
                widgetToActivate = Integer.valueOf(loadWidgetNameNumber[1]);
                //Load the container for the current widget[w]
                int containerToApply = loadWidgetSettings.getInt(loadedWidgetsArray[w]);

                wm.widgets.get(widgetToActivate).setIsActive(true);//activate the new widget
                wm.widgets.get(widgetToActivate).setContainer(containerToApply);//map it to the container that was loaded!
                println("LoadGUISettings: Applied Widget " + widgetToActivate + " to Container " + containerToApply);
        }//end case for all widget/container settings

        /////////////////////////////////////////////////////////////
        //    Load more widget settings above this line as above   //
        /////////////////////////////////////////////////////////////

        /////////////////////////////////////////////////////////////
        //              Apply Settings below this line             //
        /////////////////////////////////////////////////////////////

        //Apply Data Smoothing for capable boards
        if (currentBoard instanceof SmoothingCapableBoard) {
            ((SmoothingCapableBoard)currentBoard).setSmoothingActive(loadDataSmoothingSetting);
            topNav.updateSmoothingButtonText();
        }

        //Load and apply all of the settings that are in dropdown menus. It's a bit much, so it has it's own function below.
        loadApplyWidgetDropdownText();

        //Apply Time Series Settings Last!!!
        loadApplyTimeSeriesSettings();

        if (w_headPlot != null) {
            //FIX ME
            /*
            //Force headplot to redraw if it is active
            int hpWidgetNumber;
            if (eegDataSource == DATASOURCE_GANGLION) {
                hpWidgetNumber = 6;
            } else {
                hpWidgetNumber = 5;
            }
            if (wm.widgets.get(hpWidgetNumber).getIsActive()) {
                w_headPlot.headPlot.setPositionSize(w_headPlot.headPlot.hp_x, w_headPlot.headPlot.hp_y, w_headPlot.headPlot.hp_w, w_headPlot.headPlot.hp_h, w_headPlot.headPlot.hp_win_x, w_headPlot.headPlot.hp_win_y);
                println("Headplot is active: Redrawing");
            }
            */
        }
    } //end of loadGUISettings
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private void loadApplyWidgetDropdownText() {

        ////////Apply Time Series dropdown settings in loadApplyTimeSeriesSettings() instead of here

        ////////Apply FFT settings
        //FIX ME
        /*
        MaxFreq(fftMaxFrqLoad); //This changes the back-end
            w_fft.cp5_widget.getController("MaxFreq").getCaptionLabel().setText(fftMaxFrqArray[fftMaxFrqLoad]); //This changes front-end... etc.

        VertScale(fftMaxuVLoad);
            w_fft.cp5_widget.getController("VertScale").getCaptionLabel().setText(fftVertScaleArray[fftMaxuVLoad]);

        LogLin(fftLogLinLoad);
            w_fft.cp5_widget.getController("LogLin").getCaptionLabel().setText(fftLogLinArray[fftLogLinLoad]);

        Smoothing(fftSmoothingLoad);
            w_fft.cp5_widget.getController("Smoothing").getCaptionLabel().setText(fftSmoothingArray[fftSmoothingLoad]);

        UnfiltFilt(fftFilterLoad);
            w_fft.cp5_widget.getController("UnfiltFilt").getCaptionLabel().setText(fftFilterArray[fftFilterLoad]);
        */

        ////////Apply Accelerometer settings
        //FIX ME
        /*
        if (w_accelerometer != null) {
            accelVertScale(loadAccelVertScale);
                w_accelerometer.cp5_widget.getController("accelVertScale").getCaptionLabel().setText(accVertScaleArray[loadAccelVertScale]);

            accelDuration(loadAccelHorizScale);
                w_accelerometer.cp5_widget.getController("accelDuration").getCaptionLabel().setText(accHorizScaleArray[loadAccelHorizScale]);
        }
        */

        ////////Apply Anolog Read dropdowns to Live Cyton Only
        //FIX ME
        /*
        if (eegDataSource == DATASOURCE_CYTON) {
            VertScale_AR(loadAnalogReadVertScale);
                w_analogRead.cp5_widget.getController("VertScale_AR").getCaptionLabel().setText(arVertScaleArray[loadAnalogReadVertScale]);

            Duration_AR(loadAnalogReadHorizScale);
                w_analogRead.cp5_widget.getController("Duration_AR").getCaptionLabel().setText(arHorizScaleArray[loadAnalogReadHorizScale]);
        }
        */

        ////////////////////////////Apply Headplot settings
        //FIX ME
        /*
        if (w_headPlot != null) {
            Intensity(hpIntensityLoad);
                w_headPlot.cp5_widget.getController("Intensity").getCaptionLabel().setText(hpIntensityArray[hpIntensityLoad]);

            Polarity(hpPolarityLoad);
                w_headPlot.cp5_widget.getController("Polarity").getCaptionLabel().setText(hpPolarityArray[hpPolarityLoad]);

            ShowContours(hpContoursLoad);
                w_headPlot.cp5_widget.getController("ShowContours").getCaptionLabel().setText(hpContoursArray[hpContoursLoad]);

            SmoothingHeadPlot(hpSmoothingLoad);
                w_headPlot.cp5_widget.getController("SmoothingHeadPlot").getCaptionLabel().setText(hpSmoothingArray[hpSmoothingLoad]);

            //Force redraw headplot on load. Fixes issue where heaplot draws outside of the widget.
            w_headPlot.headPlot.setPositionSize(w_headPlot.headPlot.hp_x, w_headPlot.headPlot.hp_y, w_headPlot.headPlot.hp_w, w_headPlot.headPlot.hp_h, w_headPlot.headPlot.hp_win_x, w_headPlot.headPlot.hp_win_y);
        }
        */

        ////////////////////////////Apply Band Power settings

        //FIX ME
        /*
        try {
            //apply channel checkbox settings
            w_bandPower.bpChanSelect.deactivateAllButtons();;
            for (int i = 0; i < loadBPActiveChans.size(); i++) {
                w_bandPower.bpChanSelect.setToggleState(loadBPActiveChans.get(i), true);
            }
        } catch (Exception e) {
            println("Settings: Exception caught applying band power settings " + e);
        }
        verbosePrint("Settings: Band Power Active Channels: " + loadBPActiveChans);
        w_bandPower.setAutoClean(loadBPAutoClean);
        w_bandPower.cp5_widget.getController("bpAutoCleanDropdown").getCaptionLabel().setText(w_bandPower.getAutoClean().getString());
        w_bandPower.setAutoCleanThreshold(loadBPAutoCleanThreshold);
        w_bandPower.cp5_widget.getController("bpAutoCleanThresholdDropdown").getCaptionLabel().setText(w_bandPower.getAutoCleanThreshold().getString());
        w_bandPower.setAutoCleanTimer(loadBPAutoCleanTimer);
        w_bandPower.cp5_widget.getController("bpAutoCleanTimerDropdown").getCaptionLabel().setText(w_bandPower.getAutoCleanTimer().getString());
        */

        ////////////////////////////Apply Spectrogram settings
        //Apply Max Freq dropdown
        //FIX ME
        /*
        SpectrogramMaxFreq(spectMaxFrqLoad);
        w_spectrogram.cp5_widget.getController("SpectrogramMaxFreq").getCaptionLabel().setText(spectMaxFrqArray[spectMaxFrqLoad]);
        SpectrogramSampleRate(spectSampleRateLoad);
        w_spectrogram.cp5_widget.getController("SpectrogramSampleRate").getCaptionLabel().setText(spectSampleRateArray[spectSampleRateLoad]);
        SpectrogramLogLin(spectLogLinLoad);
        */
        //FIX ME
        //w_spectrogram.cp5_widget.getController("SpectrogramLogLin").getCaptionLabel().setText(fftLogLinArray[spectLogLinLoad]);
        try {
            //apply channel checkbox settings
            w_spectrogram.spectChanSelectTop.deactivateAllButtons();
            w_spectrogram.spectChanSelectBot.deactivateAllButtons();
            //close channel select when loading to prevent UI issues
            w_spectrogram.spectChanSelectTop.setIsVisible(false);
            w_spectrogram.spectChanSelectBot.setIsVisible(false);
            for (int i = 0; i < loadSpectActiveChanTop.size(); i++) {
                w_spectrogram.spectChanSelectTop.setToggleState(loadSpectActiveChanTop.get(i), true);
            }
            for (int i = 0; i < loadSpectActiveChanBot.size(); i++) {
                w_spectrogram.spectChanSelectBot.setToggleState(loadSpectActiveChanBot.get(i), true);
            }
            w_spectrogram.screenResized();
        } catch (Exception e) {
            println("Settings: Exception caught applying spectrogram settings channel bar " + e);
        }
        println("Settings: Spectrogram Active Channels: TOP - " + loadSpectActiveChanTop + " || BOT - " + loadSpectActiveChanBot);

        ///////////Apply Networking Settings
        String nwSettingsString = loadNetworkingSettings.toString();
        dataProcessing.networkingSettings.loadJson(nwSettingsString);
        
        ////////////////////////////Apply EMG widget settings
        try {
            //apply channel checkbox settings
            w_emg.emgChannelSelect.deactivateAllButtons();;
            for (int i = 0; i < loadEmgActiveChannels.size(); i++) {
                w_emg.emgChannelSelect.setToggleState(loadEmgActiveChannels.get(i), true);
            }
        } catch (Exception e) {
            println("Settings: Exception caught applying EMG widget settings " + e);
        }
        verbosePrint("Settings: EMG Widget Active Channels: " + loadEmgActiveChannels);

        ////////////////////////////Apply EMG Joystick settings
        w_emgJoystick.setJoystickSmoothing(loadEmgJoystickSmoothing);
        w_emgJoystick.cp5_widget.getController("emgJoystickSmoothingDropdown").getCaptionLabel()
                .setText(EmgJoystickSmoothing.getEnumStringsAsList().get(loadEmgJoystickSmoothing));
        try {
            for (int i = 0; i < loadEmgJoystickInputs.size(); i++) {
                w_emgJoystick.updateJoystickInput(i, loadEmgJoystickInputs.get(i));
            }
        } catch (Exception e) {
            println("Settings: Exception caught applying EMG Joystick settings " + e);
        }

        ////////////////////////////Apply Marker Widget settings
        w_marker.setMarkerWindow(loadMarkerWindow);
        w_marker.cp5_widget.getController("markerWindowDropdown").getCaptionLabel().setText(w_marker.getMarkerWindow().getString());
        w_marker.setMarkerVertScale(loadMarkerVertScale);
        w_marker.cp5_widget.getController("markerVertScaleDropdown").getCaptionLabel().setText(w_marker.getMarkerVertScale().getString());

        ////////////////////////////Apply Focus Widget settings
        w_focus.setMetric(loadFocusMetric);
        w_focus.cp5_widget.getController("focusMetricDropdown").getCaptionLabel().setText(w_focus.getFocusMetric().getString());
        w_focus.setThreshold(loadFocusThreshold);
        w_focus.cp5_widget.getController("focusThresholdDropdown").getCaptionLabel().setText(w_focus.getFocusThreshold().getString());
        w_focus.setFocusHorizScale(loadFocusWindow);
        w_focus.cp5_widget.getController("focusWindowDropdown").getCaptionLabel().setText(w_focus.getFocusWindow().getString());

        ////////////////////////////////////////////////////////////
        //    Apply more loaded widget settings above this line   //

    } //end of loadApplyWidgetDropdownText()

    private void loadApplyTimeSeriesSettings() {

        JSONObject loadTimeSeriesSettings = loadSettingsJSONData.getJSONObject(kJSONKeyTimeSeries);
        ////////Apply Time Series widget settings
        w_timeSeries.setVerticalScale(loadTimeSeriesSettings.getInt("Time Series Vert Scale"));
        w_timeSeries.cp5_widget.getController("VertScale_TS").getCaptionLabel().setText(w_timeSeries.getVerticalScale().getString()); //changes front-end
        
        w_timeSeries.setHorizontalScale(loadTimeSeriesSettings.getInt("Time Series Horiz Scale"));
        w_timeSeries.cp5_widget.getController("Duration").getCaptionLabel().setText(w_timeSeries.getHorizontalScale().getString());

        w_timeSeries.setLabelMode(loadTimeSeriesSettings.getInt("Time Series Label Mode"));
        w_timeSeries.cp5_widget.getController("LabelMode_TS").getCaptionLabel().setText(w_timeSeries.getLabelMode().getString());

        JSONArray loadTSChan = loadTimeSeriesSettings.getJSONArray("activeChannels");
        w_timeSeries.tsChanSelect.deactivateAllButtons();
        try {
            for (int i = 0; i < loadTSChan.size(); i++) {
                w_timeSeries.tsChanSelect.setToggleState(loadTSChan.getInt(i), true);
            }
        } catch (Exception e) {
            println("Settings: Exception caught applying time series settings " + e);
        }
        verbosePrint("Settings: Time Series Active Channels: " + loadBPActiveChans);
            
    } //end loadApplyTimeSeriesSettings

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
            fileNames = defaultSettingsFiles;
        } else if (_mode.equals("User")) {
            fileNames = userSettingsFiles;
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
            File fileToSave = dataFile(settings.getPath("User", eegDataSource, globalChannelCount));
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

} //end of Software Settings class

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
        settings.saveDialogName = selection.getAbsolutePath();
        settings.save(settings.saveDialogName); //save current settings to JSON file in SavedData
        outputSuccess("Settings Saved! Using Expert Mode, you can load these settings using 'N' key. Click \"Default\" to revert to factory settings."); //print success message to screen
        settings.saveDialogName = null; //reset this variable for future use
    }
}
// Select file to load custom settings using dropdown in TopNav.pde
void loadConfigFile(File selection) {
    if (selection == null) {
        println("SessionSettings: loadConfigFile: Window was closed or the user hit cancel.");
    } else {
        println("SessionSettings: loadConfigFile: User selected " + selection.getAbsolutePath());
        //output("You have selected \"" + selection.getAbsolutePath() + "\" to Load custom settings.");
        settings.loadDialogName = selection.getAbsolutePath();
        try {
            settings.load(settings.loadDialogName); //load settings from JSON file in /data/
            //Output success message when Loading settings is complete without errors
            if (settings.chanNumError == false
                && settings.dataSourceError == false
                && settings.loadErrorCytonEvent == false) {
                    outputSuccess("Settings Loaded!");
                }
        } catch (Exception e) {
            println("SessionSettings: Incompatible settings file or other error");
            if (settings.chanNumError == true) {
                outputError("Settings Error:  Channel Number Mismatch Detected");
            } else if (settings.dataSourceError == true) {
                outputError("Settings Error: Data Source Mismatch Detected");
            } else {
                outputError("Error trying to load settings file, possibly from previous GUI. Removing old settings.");
                if (selection.exists()) selection.delete();
            }
        }
        settings.loadDialogName = null; //reset this variable for future use
    }
}