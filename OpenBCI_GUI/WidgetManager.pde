//========================================================================================
//=================              ADD NEW WIDGETS HERE            =========================
//========================================================================================
/*
    Notes:
    - The order in which they are added will effect the order in which they appear in the GUI and in the WidgetSelector dropdown menu of each widget
    - Use the WidgetTemplate.pde file as a starting point for creating new widgets (also check out W_TimeSeries.pde, W_Fft.pde, and W_HeadPlot.pde)
*/
//========================================================================================
//========================================================================================
//========================================================================================

class WidgetManager {
    //This holds all of the widgets. When creating/adding new widgets, we will add them to this ArrayList (below)
    private ArrayList<Widget> widgets;
    private ArrayList<String> widgetOptions; //List of Widget Titles, used to populate cp5 widgetSelector dropdown of all widgets
    private int currentContainerLayout; //This is the Layout structure for the main body of the GUI
    private ArrayList<Layout> layouts = new ArrayList<Layout>();  //This holds all of the different layouts ...

    private boolean visible = true;

    WidgetManager() {
        widgets = new ArrayList<Widget>();
        widgetOptions = new ArrayList<String>();

        //DO NOT re-order the functions below
        setupLayouts();
        setupWidgets();
        setupWidgetSelectorDropdowns();

        if ((globalChannelCount == 4 && eegDataSource == DATASOURCE_GANGLION) || eegDataSource == DATASOURCE_PLAYBACKFILE) {
            currentContainerLayout = 1;
            sessionSettings.currentLayout = 1;
        } else {
            currentContainerLayout = 4; //default layout ... tall container left and 2 shorter containers stacked on the right
            sessionSettings.currentLayout = 4;
        }

        setNewContainerLayout(currentContainerLayout); //sets and fills layout with widgets in order of widget index, to reorganize widget index, reorder the creation in setupWidgets()
    }

    void setupWidgets() {

        widgets.add(new W_TimeSeries());

        widgets.add(new W_Fft());

        if (currentBoard instanceof AccelerometerCapableBoard) {
            widgets.add(new W_Accelerometer());
        }

        if (currentBoard instanceof BoardCyton) {
            widgets.add(new W_CytonImpedance());
        }

        if (currentBoard instanceof DataSourcePlayback) {
            widgets.add(new W_playback());
        }

        if (globalChannelCount == 4 && currentBoard instanceof BoardGanglion) {
            widgets.add(new W_GanglionImpedance());
        }

        widgets.add(new W_Focus());

        widgets.add(new W_BandPower());

        widgets.add(new W_HeadPlot());

        widgets.add(new W_Emg());
    
        widgets.add(new W_EmgJoystick());

        widgets.add(new W_Spectrogram());

        if (currentBoard instanceof AnalogCapableBoard) {
            widgets.add(new W_PulseSensor());
        }

        if (currentBoard instanceof DigitalCapableBoard) {
            widgets.add(new W_DigitalRead());
        }
        
        if (currentBoard instanceof AnalogCapableBoard) {
            widgets.add(new W_AnalogRead());
        }

        if (currentBoard instanceof Board) {
            widgets.add(new W_PacketLoss());
        }

        widgets.add(new W_Marker());
        
        //DEVELOPERS: Here is an example widget with the essentials/structure in place
        widgets.add(new W_Template());
    }

    void setupWidgetSelectorDropdowns() {
        //create the widgetSelector dropdown of each widget
        //println("widgets.size() = " + widgets.size());
        //create list of WidgetTitles.. we will use this to populate the dropdown (widget selector) of each widget
        for (int i = 0; i < widgets.size(); i++) {
            widgetOptions.add(widgets.get(i).widgetTitle);
        }
        //println("widgetOptions.size() = " + widgetOptions.size());
        for (int i = 0; i <widgetOptions.size(); i++) {
            widgets.get(i).setupWidgetSelectorDropdown(widgetOptions);
            widgets.get(i).setupNavDropdowns();
        }
    }

    void update() {
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                widgets.get(i).update();
                //if the widgets are not mapped to containers correctly, remap them..
                // if (widgets.get(i).x != container[widgets.get(i).currentContainer].x || widgets.get(i).y != container[widgets.get(i).currentContainer].y || widgets.get(i).w != container[widgets.get(i).currentContainer].w || widgets.get(i).h != container[widgets.get(i).currentContainer].h) {
                if (widgets.get(i).x0 != (int)container[widgets.get(i).currentContainer].x || widgets.get(i).y0 != (int)container[widgets.get(i).currentContainer].y || widgets.get(i).w0 != (int)container[widgets.get(i).currentContainer].w || widgets.get(i).h0 != (int)container[widgets.get(i).currentContainer].h) {
                    screenResized();
                    println("WidgetManager.pde: Remapping widgets to container layout...");
                }
            }
        }
    }

    void draw() {
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                widgets.get(i).draw();
                widgets.get(i).drawDropdowns();
            }
        }
    }

    void screenResized() {
        for (int i = 0; i < widgets.size(); i++) {
            widgets.get(i).screenResized();
        }
    }

    void mousePressed() {
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                widgets.get(i).mousePressed();
            }

        }
    }

    void mouseReleased() {
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                widgets.get(i).mouseReleased();
            }
        }
    }

    void mouseDragged() {
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                widgets.get(i).mouseDragged();
            }
        }
    }

    void setupLayouts() {
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

    void printLayouts() {
        for (int i = 0; i < layouts.size(); i++) {
            println("Widget Manager:printLayouts: " + layouts.get(i));
            String layoutString = "";
            for (int j = 0; j < layouts.get(i).myContainers.length; j++) {
                // println("Widget Manager:layoutContainers: " + layouts.get(i).myContainers[j]);
                layoutString += layouts.get(i).myContainers[j].x + ", ";
                layoutString += layouts.get(i).myContainers[j].y + ", ";
                layoutString += layouts.get(i).myContainers[j].w + ", ";
                layoutString += layouts.get(i).myContainers[j].h;
            }
            println("Widget Manager:printLayouts: " + layoutString);
        }
    }

    void setNewContainerLayout(int _newLayout) {

        //find out how many active widgets we need...
        int numActiveWidgetsNeeded = layouts.get(_newLayout).myContainers.length;
        //calculate the number of current active widgets & keep track of which widgets are active
        int numActiveWidgets = 0;
        // ArrayList<int> activeWidgets = new ArrayList<int>();
        for (int i = 0; i < widgets.size(); i++) {
            if (widgets.get(i).getIsActive()) {
                numActiveWidgets++; //increment numActiveWidgets
                // activeWidgets.add(i); //keep track of the active widget
            }
        }

        if (numActiveWidgets > numActiveWidgetsNeeded) { //if there are more active widgets than needed
            //shut some down
            int numToShutDown = numActiveWidgets - numActiveWidgetsNeeded;
            int counter = 0;
            println("Widget Manager: Powering " + numToShutDown + " widgets down, and remapping.");
            for (int i = widgets.size()-1; i >= 0; i--) {
                if (widgets.get(i).getIsActive() && counter < numToShutDown) {
                    verbosePrint("Widget Manager: Deactivating widget [" + i + "]");
                    widgets.get(i).setIsActive(false);
                    counter++;
                }
            }

            //and map active widgets
            counter = 0;
            for (int i = 0; i < widgets.size(); i++) {
                if (widgets.get(i).getIsActive()) {
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    counter++;
                }
            }

        } else if (numActiveWidgetsNeeded > numActiveWidgets) { //if there are less active widgets than needed
            //power some up
            int numToPowerUp = numActiveWidgetsNeeded - numActiveWidgets;
            int counter = 0;
            verbosePrint("Widget Manager: Powering " + numToPowerUp + " widgets up, and remapping.");
            for (int i = 0; i < widgets.size(); i++) {
                if (!widgets.get(i).getIsActive() && counter < numToPowerUp) {
                    verbosePrint("Widget Manager: Activating widget [" + i + "]");
                    widgets.get(i).setIsActive(true);
                    counter++;
                }
            }

            //and map active widgets
            counter = 0;
            for (int i = 0; i < widgets.size(); i++) {
                if (widgets.get(i).getIsActive()) {
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    // widgets.get(i).screenResized(); // do this to make sure the container is updated
                    counter++;
                }
            }

        } else{ //if there are the same amount
            //simply remap active widgets
            verbosePrint("Widget Manager: Remapping widgets.");
            int counter = 0;
            for (int i = 0; i < widgets.size(); i++) {
                if (widgets.get(i).getIsActive()) {
                    widgets.get(i).setContainer(layouts.get(_newLayout).containerInts[counter]);
                    counter++;
                }
            }
        }
    }

    public void setAllWidgetsNull() {
        widgets.clear();
        println("Widget Manager: All widgets set to null.");
    }

    // Useful in places like TopNav which overlap widget dropdowns
    public void lockCp5ObjectsInAllWidgets(boolean lock) {
        for (int i = 0; i < widgets.size(); i++) {
            for (int j = 0; j < widgets.get(i).cp5_widget.getAll().size(); j++) {
                ControlP5 cp5Instance = widgets.get(i).cp5_widget;
                String widgetAddress = cp5Instance.getAll().get(j).getAddress();
                cp5Instance.getController(widgetAddress).setLock(lock);
            }
        }
    }

    public Widget getWidget(String className) {
        for (int i = 0; i < widgets.size(); i++) {
            Widget widget = widgets.get(i);
            // Get the class name of the widget
            String widgetClassName = widget.getClass().getSimpleName();
            // Check if it matches the requested class name
            if (widgetClassName.equals(className)) {
                return widget;
            }
        }
        // Return null if no widget of the specified class is found
        return null;
    }

    public boolean getWidgetExists(String className) {
        Widget widget = getWidget(className);
        return widget != null;
    }

    public W_TimeSeries getTimeSeriesWidget() {
        return (W_TimeSeries) getWidget("W_TimeSeries");
    }
};