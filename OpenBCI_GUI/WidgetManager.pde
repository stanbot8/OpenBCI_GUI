//========================================================================================
//=================              ADD NEW WIDGETS HERE            =========================
//========================================================================================
/*
    Notes:
    - In this file all you have to do is MAKE YOUR WIDGET GLOBALLY, and then ADD YOUR WIDGET TO WIDGETS OF WIDGETMANAGER in the setupWidgets() function below
    - the order in which they are added will effect the order in which they appear in the GUI and in the WidgetSelector dropdown menu of each widget
    - use the WidgetTemplate.pde file as a starting point for creating new widgets (also check out W_timeSeries.pde, W_fft.pde, and W_HeadPlot.pde)
*/

// MAKE YOUR WIDGET GLOBALLY
W_timeSeries w_timeSeries;
W_fft w_fft;
W_BandPower w_bandPower;
W_Accelerometer w_accelerometer;
W_CytonImpedance w_cytonImpedance;
W_GanglionImpedance w_ganglionImpedance;
W_HeadPlot w_headPlot;
W_template w_template1;
W_emg w_emg;
W_PulseSensor w_pulseSensor;
W_AnalogRead w_analogRead;
W_DigitalRead w_digitalRead;
W_playback w_playback;
W_Spectrogram w_spectrogram;
W_Focus w_focus;
W_EMGJoystick w_emgJoystick;
W_Marker w_marker;
W_PacketLoss w_packetLoss;

//========================================================================================
//========================================================================================
//========================================================================================

class WidgetManager{

    //this holds all of the widgets ... when creating/adding new widgets, we will add them to this ArrayList (below)
    ArrayList<Widget> widgets;
    ArrayList<String> widgetOptions; //List of Widget Titles, used to populate cp5 widgetSelector dropdown of all widgets

    //Variables for
    int currentContainerLayout; //this is the Layout structure for the main body of the GUI ... refer to [PUT_LINK_HERE] for layouts/numbers image
    ArrayList<Layout> layouts = new ArrayList<Layout>();  //this holds all of the different layouts ...

    public boolean isWMInitialized = false;
    private boolean visible = true;

    WidgetManager(PApplet _this){
        widgets = new ArrayList<Widget>();
        widgetOptions = new ArrayList<String>();
        isWMInitialized = false;

        //DO NOT re-order the functions below
        setupLayouts();
        setupWidgets(_this);
        setupWidgetSelectorDropdowns();

        if(globalChannelCount == 4 && eegDataSource == DATASOURCE_GANGLION) {
            currentContainerLayout = 1;
            settings.currentLayout = 1; // used for save/load settings
            setNewContainerLayout(currentContainerLayout); //sets and fills layout with widgets in order of widget index, to reorganize widget index, reorder the creation in setupWidgets()
        } else if (eegDataSource == DATASOURCE_PLAYBACKFILE) {
            currentContainerLayout = 1;
            settings.currentLayout = 1; // used for save/load settings
            setNewContainerLayout(currentContainerLayout); //sets and fills layout with widgets in order of widget index, to reorganize widget index, reorder the creation in setupWidgets()
        } else {
            currentContainerLayout = 4; //default layout ... tall container left and 2 shorter containers stacked on the right
            settings.currentLayout = 4; // used for save/load settings
            setNewContainerLayout(currentContainerLayout); //sets and fills layout with widgets in order of widget index, to reorganize widget index, reorder the creation in setupWidgets()
        }

        isWMInitialized = true;
    }

    void setupWidgets(PApplet _this) {
        // println("  setupWidgets start -- " + millis());

        w_timeSeries = new W_timeSeries(_this);
        w_timeSeries.setTitle("Time Series");
        widgets.add(w_timeSeries);

        w_fft = new W_fft(_this);
        w_fft.setTitle("FFT Plot");
        widgets.add(w_fft);

        boolean showAccelerometerWidget = currentBoard instanceof AccelerometerCapableBoard;
        if (showAccelerometerWidget) {
            w_accelerometer = new W_Accelerometer(_this);
            w_accelerometer.setTitle("Accelerometer");
            widgets.add(w_accelerometer);
        }

        if (currentBoard instanceof BoardCyton) {
            w_cytonImpedance = new W_CytonImpedance(_this);
            w_cytonImpedance.setTitle("Cyton Signal");
            widgets.add(w_cytonImpedance);
        }

        if (currentBoard instanceof DataSourcePlayback && w_playback == null) {
            w_playback = new W_playback(_this);
            w_playback.setTitle("Playback History");
            widgets.add(w_playback);
        }

        //only instantiate this widget if you are using a Ganglion board for live streaming
        if(globalChannelCount == 4 && currentBoard instanceof BoardGanglion){
            //If using Ganglion, this is Widget_3
            w_ganglionImpedance = new W_GanglionImpedance(_this);
            w_ganglionImpedance.setTitle("Ganglion Signal");
            widgets.add(w_ganglionImpedance);
        }

        w_focus = new W_Focus(_this);
        w_focus.setTitle("Focus");
        widgets.add(w_focus);

        w_bandPower = new W_BandPower(_this);
        w_bandPower.setTitle("Band Power");
        widgets.add(w_bandPower);

        w_headPlot = new W_HeadPlot(_this);
        w_headPlot.setTitle("Head Plot");
        widgets.add(w_headPlot);

        w_emg = new W_emg(_this);
        w_emg.setTitle("EMG");
        widgets.add(w_emg);
    
        w_emgJoystick = new W_EMGJoystick(_this);
        w_emgJoystick.setTitle("EMG Joystick");
        widgets.add(w_emgJoystick);

        w_spectrogram = new W_Spectrogram(_this);
        w_spectrogram.setTitle("Spectrogram");
        widgets.add(w_spectrogram);

        if (currentBoard instanceof AnalogCapableBoard){
            w_pulseSensor = new W_PulseSensor(_this);
            w_pulseSensor.setTitle("Pulse Sensor");
            widgets.add(w_pulseSensor);
        }

        if (currentBoard instanceof DigitalCapableBoard) {
            w_digitalRead = new W_DigitalRead(_this);
            w_digitalRead.setTitle("Digital Read");
            widgets.add(w_digitalRead);
        }
        
        if (currentBoard instanceof AnalogCapableBoard) {
            w_analogRead = new W_AnalogRead(_this);
            w_analogRead.setTitle("Analog Read");
            widgets.add(w_analogRead);
        }

        if (currentBoard instanceof Board) {
            w_packetLoss = new W_PacketLoss(_this);
            w_packetLoss.setTitle("Packet Loss");
            widgets.add(w_packetLoss);
        }

        w_marker = new W_Marker(_this);
        w_marker.setTitle("Marker");
        widgets.add(w_marker);
        
        //DEVELOPERS: Here is an example widget with the essentials/structure in place
        w_template1 = new W_template(_this);
        w_template1.setTitle("Widget Template 1");
        widgets.add(w_template1);
    }


    public boolean isVisible() {
        return visible;
    }

    public void setVisible(boolean _visible) {
        visible = _visible;
    }

    void setupWidgetSelectorDropdowns(){
        //create the widgetSelector dropdown of each widget
        //println("widgets.size() = " + widgets.size());
        //create list of WidgetTitles.. we will use this to populate the dropdown (widget selector) of each widget
        for(int i = 0; i < widgets.size(); i++){
            widgetOptions.add(widgets.get(i).widgetTitle);
        }
        //println("widgetOptions.size() = " + widgetOptions.size());
        for(int i = 0; i <widgetOptions.size(); i++){
            widgets.get(i).setupWidgetSelectorDropdown(widgetOptions);
            widgets.get(i).setupNavDropdowns();
        }
    }

    void update(){
        if(visible){
            for(int i = 0; i < widgets.size(); i++){
                if(widgets.get(i).getIsActive()){
                    widgets.get(i).update();
                    //if the widgets are not mapped to containers correctly, remap them..
                    // if(widgets.get(i).x != container[widgets.get(i).currentContainer].x || widgets.get(i).y != container[widgets.get(i).currentContainer].y || widgets.get(i).w != container[widgets.get(i).currentContainer].w || widgets.get(i).h != container[widgets.get(i).currentContainer].h){
                    if(widgets.get(i).x0 != (int)container[widgets.get(i).currentContainer].x || widgets.get(i).y0 != (int)container[widgets.get(i).currentContainer].y || widgets.get(i).w0 != (int)container[widgets.get(i).currentContainer].w || widgets.get(i).h0 != (int)container[widgets.get(i).currentContainer].h){
                        screenResized();
                        println("WidgetManager.pde: Remapping widgets to container layout...");
                    }
                }
            }
        }
    }

    void draw(){
        if(visible){
            for(int i = 0; i < widgets.size(); i++){
                if(widgets.get(i).getIsActive()){
                    widgets.get(i).draw();
                    widgets.get(i).drawDropdowns();
                }
            }
        }
    }

    void screenResized(){
        for(int i = 0; i < widgets.size(); i++){
            widgets.get(i).screenResized();
        }
    }

    void mousePressed(){
        for(int i = 0; i < widgets.size(); i++){
            if(widgets.get(i).getIsActive()){
                widgets.get(i).mousePressed();
            }

        }
    }

    void mouseReleased(){
        for(int i = 0; i < widgets.size(); i++){
            if(widgets.get(i).getIsActive()){
                widgets.get(i).mouseReleased();
            }
        }
    }

    void mouseDragged(){
        for(int i = 0; i < widgets.size(); i++){
            if(widgets.get(i).getIsActive()){
                widgets.get(i).mouseDragged();
            }
        }
    }

    void setupLayouts(){
        //refer to [PUT_LINK_HERE] for layouts/numbers image
        //note that the order you create/add these layouts matters... if you reorganize these, the LayoutSelector will be out of order
        layouts.add(new Layout(new int[]{5})); //layout 1
        layouts.add(new Layout(new int[]{1,3,7,9})); //layout 2
        layouts.add(new Layout(new int[]{4,6})); //layout 3
        layouts.add(new Layout(new int[]{2,8})); //etc.
        layouts.add(new Layout(new int[]{4,3,9}));
        layouts.add(new Layout(new int[]{1,7,6}));
        layouts.add(new Layout(new int[]{1,3,8}));
        layouts.add(new Layout(new int[]{2,7,9}));
        layouts.add(new Layout(new int[]{4,11,12,13,14}));
        layouts.add(new Layout(new int[]{4,15,16,17,18}));
        layouts.add(new Layout(new int[]{1,7,11,12,13,14}));
        layouts.add(new Layout(new int[]{1,7,15,16,17,18}));
    }

    void printLayouts(){
        for(int i = 0; i < layouts.size(); i++){
            println("Widget Manager:printLayouts: " + layouts.get(i));
            String layoutString = "";
            for(int j = 0; j < layouts.get(i).myContainers.length; j++){
                // println("Widget Manager:layoutContainers: " + layouts.get(i).myContainers[j]);
                layoutString += layouts.get(i).myContainers[j].x + ", ";
                layoutString += layouts.get(i).myContainers[j].y + ", ";
                layoutString += layouts.get(i).myContainers[j].w + ", ";
                layoutString += layouts.get(i).myContainers[j].h;
            }
            println("Widget Manager:printLayouts: " + layoutString);
        }
    }

    void setNewContainerLayout(int _newLayout){

        //find out how many active widgets we need...
        int numActiveWidgetsNeeded = layouts.get(_newLayout).myContainers.length;
        //calculate the number of current active widgets & keep track of which widgets are active
        int numActiveWidgets = 0;
        // ArrayList<int> activeWidgets = new ArrayList<int>();
        for(int i = 0; i < widgets.size(); i++){
            if(widgets.get(i).getIsActive()){
                numActiveWidgets++; //increment numActiveWidgets
                // activeWidgets.add(i); //keep track of the active widget
            }
        }

        if(numActiveWidgets > numActiveWidgetsNeeded){ //if there are more active widgets than needed
            //shut some down
            int numToShutDown = numActiveWidgets - numActiveWidgetsNeeded;
            int counter = 0;
            println("Widget Manager: Powering " + numToShutDown + " widgets down, and remapping.");
            for(int i = widgets.size()-1; i >= 0; i--){
                if(widgets.get(i).getIsActive() && counter < numToShutDown){
                    verbosePrint("Widget Manager: Deactivating widget [" + i + "]");
                    widgets.get(i).setIsActive(false);
                    counter++;
                }
            }

            //and map active widgets
            counter = 0;
            for(int i = 0; i < widgets.size(); i++){
                if(widgets.get(i).getIsActive()){
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    counter++;
                }
            }

        } else if(numActiveWidgetsNeeded > numActiveWidgets){ //if there are less active widgets than needed
            //power some up
            int numToPowerUp = numActiveWidgetsNeeded - numActiveWidgets;
            int counter = 0;
            verbosePrint("Widget Manager: Powering " + numToPowerUp + " widgets up, and remapping.");
            for(int i = 0; i < widgets.size(); i++){
                if(!widgets.get(i).getIsActive() && counter < numToPowerUp){
                    verbosePrint("Widget Manager: Activating widget [" + i + "]");
                    widgets.get(i).setIsActive(true);
                    counter++;
                }
            }

            //and map active widgets
            counter = 0;
            for(int i = 0; i < widgets.size(); i++){
                if(widgets.get(i).getIsActive()){
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    // widgets.get(i).screenResized(); // do this to make sure the container is updated
                    counter++;
                }
            }

        } else{ //if there are the same amount
            //simply remap active widgets
            verbosePrint("Widget Manager: Remapping widgets.");
            int counter = 0;
            for(int i = 0; i < widgets.size(); i++){
                if(widgets.get(i).getIsActive()){
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    counter++;
                }
            }
        }
    }

    public void setAllWidgetsNull() {
        widgets.clear();
        w_timeSeries = null;
        w_fft = null;
        w_bandPower = null;
        w_accelerometer = null;
        w_cytonImpedance = null;
        w_ganglionImpedance = null;
        w_headPlot = null;
        w_template1 = null;
        w_emg = null;
        w_pulseSensor = null;
        w_analogRead = null;
        w_digitalRead = null;
        w_playback = null;
        w_spectrogram = null;
        w_packetLoss = null;
        w_focus = null;
        w_emgJoystick = null;
        w_marker = null;

        println("Widget Manager: All widgets set to null.");
    }
};

//the Layout class is an orgnanizational tool ... a layout consists of a combination of containers ... refer to Container.pde
class Layout{

    Container[] myContainers;
    int[] containerInts;

    Layout(int[] _myContainers){ //when creating a new layout, you pass in the integer #s of the containers you want as part of the layout ... so if I pass in the array {5}, my layout is 1 container that takes up the whole GUI body
        //constructor stuff
        myContainers = new Container[_myContainers.length]; //make the myContainers array equal to the size of the incoming array of ints
        containerInts = new int[_myContainers.length];
        for(int i = 0; i < _myContainers.length; i++){
            myContainers[i] = container[_myContainers[i]];
            containerInts[i] = _myContainers[i];
        }
    }

    Container getContainer(int _numContainer){
        if(_numContainer < myContainers.length){
            return myContainers[_numContainer];
        } else{
            println("Widget Manager: Tried to return a non-existant container...");
            return myContainers[myContainers.length-1];
        }
    }
};