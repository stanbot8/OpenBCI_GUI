
////////////////////////////////////////////////////
//
// This class creates an FFT Plot
// It extends the Widget class
//
// Conor Russomanno, November 2016
// Refactored: Richard Waltman, March 2025
//
// Requires the plotting library from grafica ...
// replacing the old gwoptics (which is now no longer supported)
//
///////////////////////////////////////////////////

class W_Fft extends Widget {

    public ExGChannelSelect fftChanSelect;
    private boolean prevChanSelectIsVisible = false;

    private GPlot fftPlot; //create an fft plot for each active channel
    private GPointsArray[] fftGplotPoints;

    private FFTMaxFrequency maxFrequency = FFTMaxFrequency.MAX_60;
    private FFTVerticalScale verticalScale = FFTVerticalScale.SCALE_100;
    private FFTLogLin logLin = FFTLogLin.LOG;

    private final int FFT_FREQUENCY_LIMIT = int(1.0 * maxFrequency.getHighestFrequency() * (getNumFFTPoints() / currentBoard.getSampleRate()));

    List<controlP5.Controller> cp5ElementsToCheck = new ArrayList<controlP5.Controller>();

    W_Fft(String _widgetName) {
        super(_widgetName);

        fftChanSelect = new ExGChannelSelect(ourApplet, x, y, w, navH);
        fftChanSelect.activateAllButtons();
        
        cp5ElementsToCheck.addAll(fftChanSelect.getCp5ElementsForOverlapCheck());

        addDropdown("fftMaxFrequencyDropdown", "Max Hz", maxFrequency.getEnumStringsAsList(), maxFrequency.getIndex());
        addDropdown("fftVerticalScaleDropdown", "Max uV", verticalScale.getEnumStringsAsList(), verticalScale.getIndex());
        addDropdown("fftLogLinDropdown", "Log/Lin", logLin.getEnumStringsAsList(), logLin.getIndex());
        FFTSmoothingFactor smoothingFactor = globalFFTSettings.getSmoothingFactor();
        FFTFilteredEnum filteredEnum = globalFFTSettings.getFilteredEnum();
        addDropdown("fftSmoothingDropdown", "Smooth", smoothingFactor.getEnumStringsAsList(), smoothingFactor.getIndex());
        addDropdown("fftFilteringDropdown", "Filters?", filteredEnum.getEnumStringsAsList(), filteredEnum.getIndex());

        fftGplotPoints = new GPointsArray[globalChannelCount];
        initializeFFTPlot();
    }

    void initializeFFTPlot() {
        //setup GPlot for FFT
        fftPlot = new GPlot(ourApplet, x, y-NAV_HEIGHT, w, h+NAV_HEIGHT);
        fftPlot.setAllFontProperties("Arial", 0, 14);
        fftPlot.getXAxis().setAxisLabelText("Frequency (Hz)");
        fftPlot.getYAxis().setAxisLabelText("Amplitude (uV)");
        fftPlot.setMar(60, 70, 40, 30); //{ bot=60, left=70, top=40, right=30 } by default
        setPlotLogScale();

        fftPlot.setYLim(0.1, verticalScale.getValue());
        int _nTicks = 10;
        fftPlot.getYAxis().setNTicks(_nTicks);  //sets the number of axis divisions...
        fftPlot.setXLim(0.1, maxFrequency.getValue());
        fftPlot.getYAxis().setDrawTickLabels(true);
        fftPlot.setPointSize(2);
        fftPlot.setPointColor(0);
        fftPlot.getXAxis().setFontColor(OPENBCI_DARKBLUE);
        fftPlot.getXAxis().setLineColor(OPENBCI_DARKBLUE);
        fftPlot.getXAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);
        fftPlot.getYAxis().setFontColor(OPENBCI_DARKBLUE);
        fftPlot.getYAxis().setLineColor(OPENBCI_DARKBLUE);
        fftPlot.getYAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);

        //setup points of fft point arrays
        for (int i = 0; i < fftGplotPoints.length; i++) {
            fftGplotPoints[i] = new GPointsArray(FFT_FREQUENCY_LIMIT);
        }

        //fill fft point arrays
        for (int i = 0; i < fftGplotPoints.length; i++) { //loop through each channel
            for (int j = 0; j < FFT_FREQUENCY_LIMIT; j++) {
                GPoint temp = new GPoint(j, 0);
                fftGplotPoints[i].set(j, temp);
            }
        }

        //map fft point arrays to fft plots
        fftPlot.setPoints(fftGplotPoints[0]);
    }

    void update(){

        super.update();
        float sampleRate = currentBoard.getSampleRate();
        int fftPointCount = getNumFFTPoints();

        //update the points of the FFT channel arrays for all channels
        for (int i = 0; i < fftGplotPoints.length; i++) {
            for (int j = 0; j < FFT_FREQUENCY_LIMIT + 2; j++) {  //loop through frequency domain data, and store into points array
                GPoint powerAtBin = new GPoint((1.0*sampleRate/fftPointCount)*j, fftBuff[i].getBand(j));
                fftGplotPoints[i].set(j, powerAtBin);
            }
        }

        //Update channel select checkboxes and active channels
        fftChanSelect.update(x, y, w);

        //Flex the Gplot graph when channel select dropdown is open/closed
        if (fftChanSelect.isVisible() != prevChanSelectIsVisible) {
            flexGPlotSizeAndPosition();
            prevChanSelectIsVisible = fftChanSelect.isVisible();
        }

        if (fftChanSelect.isVisible()) {
            lockElementsOnOverlapCheck(cp5ElementsToCheck);
        }
    }

    void draw(){
        super.draw();

        //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        pushStyle();

        //draw FFT Graph w/ all plots
        noStroke();
        fftPlot.beginDraw();
        fftPlot.drawBackground();
        fftPlot.drawBox();
        fftPlot.drawXAxis();
        fftPlot.drawYAxis();
        fftPlot.drawGridLines(GPlot.BOTH);
        //Update and draw active channels that have been selected via channel select for this widget
        for (int j = 0; j < fftChanSelect.getActiveChannels().size(); j++) {
            int chan = fftChanSelect.getActiveChannels().get(j);
            fftPlot.setLineColor((int)channelColors[chan % 8]);
            //remap fft point arrays to fft plots
            fftPlot.setPoints(fftGplotPoints[chan]);
            fftPlot.drawLines();
        }  
        fftPlot.endDraw();

        //for this widget need to redraw the grey bar, bc the FFT plot covers it up...
        fill(200, 200, 200);
        rect(x, y - NAV_HEIGHT, w, NAV_HEIGHT); //button bar

        popStyle();

        fftChanSelect.draw();
    }

    void screenResized(){
        super.screenResized();

        flexGPlotSizeAndPosition();

        fftChanSelect.screenResized(ourApplet);
    }

    void mousePressed(){
        super.mousePressed();
        fftChanSelect.mousePressed(this.dropdownIsActive); //Calls channel select mousePressed and checks if clicked
    }

    void mouseReleased(){
        super.mouseReleased();
    }

    void flexGPlotSizeAndPosition() {
        if (fftChanSelect.isVisible()) {
                fftPlot.setPos(x, y + fftChanSelect.getHeight() - navH);
                fftPlot.setOuterDim(w, h - fftChanSelect.getHeight() + navH);
        } else {
            fftPlot.setPos(x, y - navH);
            fftPlot.setOuterDim(w, h + navH);
        }
    }

    public void setMaxFrequency(int n) {
        maxFrequency = FFTMaxFrequency.values[n];
        fftPlot.setXLim(0.1, maxFrequency.getValue());
    }

    public void setVerticalScale(int n) {
        verticalScale = FFTVerticalScale.values[n];
        fftPlot.setYLim(0.1, verticalScale.getValue());
    }

    public void setLogLin(int n) {
        logLin = FFTLogLin.values[n];
        setPlotLogScale();
    }

    private void setPlotLogScale() {
        if (logLin == FFTLogLin.LOG) {
            fftPlot.setLogScale("y");
        } else {
            fftPlot.setLogScale("");
        }
    }

    public void setSmoothingDropdownFrontend(FFTSmoothingFactor _smoothingFactor) {
        String s = _smoothingFactor.getString();
        cp5_widget.getController("fftSmoothingDropdown").getCaptionLabel().setText(s);
    }

    public void setFilteringDropdownFrontend(FFTFilteredEnum _filteredEnum) {
        String s = _filteredEnum.getString();
        cp5_widget.getController("fftFilteringDropdown").getCaptionLabel().setText(s);
    }
};

//These functions need to be global! These functions are activated when an item from the corresponding dropdown is selected
public void fftMaxFrequencyDropdown(int n) {
    ((W_Fft) widgetManager.getWidget("W_Fft")).setMaxFrequency(n);
}

public void fftVerticalScaleDropdown(int n) {
    ((W_Fft) widgetManager.getWidget("W_Fft")).setVerticalScale(n);
}

public void fftLogLinDropdown(int n) {
    ((W_Fft) widgetManager.getWidget("W_Fft")).setLogLin(n);
}

public void fftSmoothingDropdown(int n) {
    globalFFTSettings.setSmoothingFactor(FFTSmoothingFactor.values()[n]);
    FFTSmoothingFactor smoothingFactor = globalFFTSettings.getSmoothingFactor();
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setSmoothingDropdownFrontend(smoothingFactor);
}

public void fftFilteringDropdown(int n) {
    globalFFTSettings.setFilteredEnum(FFTFilteredEnum.values()[n]);
    FFTFilteredEnum filteredEnum = globalFFTSettings.getFilteredEnum();
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setFilteringDropdownFrontend(filteredEnum);
}