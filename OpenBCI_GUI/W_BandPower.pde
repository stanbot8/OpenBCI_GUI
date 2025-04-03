
////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//    W_BandPowers.pde                                                                                //
//                                                                                                    //
//    This is a band power visualization widget!                                                      //
//    (Couldn't think up more)                                                                        //
//    This is for visualizing the power of each brainwave band: delta, theta, alpha, beta, gamma      //
//    Averaged over all channels                                                                      //
//                                                                                                    //
//    Created by: Wangshu Sun, May 2017                                                               //
//    Modified by: Richard Waltman, March 2022                                                        //
//    Refactored by: Richard Waltman, March 2025                                                      //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////

class W_BandPower extends Widget {

    // indexes
    private final int DELTA = 0; // 1-4 Hz
    private final int THETA = 1; // 4-8 Hz
    private final int ALPHA = 2; // 8-13 Hz
    private final int BETA = 3; // 13-30 Hz
    private final int GAMMA = 4; // 30-55 Hz
    
    private final int NUM_BANDS = 5;
    private float[] activePower = new float[NUM_BANDS];
    private float[] normalizedBandPowers = new float[NUM_BANDS];

    private GPlot bp_plot;
    public ExGChannelSelect bpChanSelect;
    private boolean prevChanSelectIsVisible = false;

    private List<controlP5.Controller> cp5ElementsToCheck = new ArrayList<controlP5.Controller>();

    BPAutoClean autoClean = BPAutoClean.OFF;
    BPAutoCleanThreshold autoCleanThreshold = BPAutoCleanThreshold.FIFTY;
    BPAutoCleanTimer autoCleanTimer = BPAutoCleanTimer.THREE_SECONDS;

    int[] autoCleanTimers;
    boolean[] previousThresholdCrossed;

    W_BandPower(PApplet _parent) {
        super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

        autoCleanTimers = new int[currentBoard.getNumEXGChannels()];
        previousThresholdCrossed = new boolean[currentBoard.getNumEXGChannels()];

        //Add channel select dropdown to this widget
        bpChanSelect = new ExGChannelSelect(pApplet, x, y, w, navH);
        bpChanSelect.activateAllButtons();

        cp5ElementsToCheck.addAll(bpChanSelect.getCp5ElementsForOverlapCheck());
        
        //Add settings dropdowns
        //Note: This is the correct way to create a dropdown using an enum -RW
        addDropdown("bandPowerAutoCleanDropdown", "AutoClean", autoClean.getEnumStringsAsList(), autoClean.getIndex());
        addDropdown("bandPowerAutoCleanThresholdDropdown", "Threshold", autoCleanThreshold.getEnumStringsAsList(), autoCleanThreshold.getIndex());
        addDropdown("bandPowerAutoCleanTimerDropdown", "Timer", autoCleanTimer.getEnumStringsAsList(), autoCleanTimer.getIndex());
        //Note: This is a legacy way to create a dropdown which is sloppy and disorganized -RW
        //These two dropdowns also have to mirror the settings in the FFT widget
        FFTSmoothingFactor smoothingFactor = globalFFTSettings.getSmoothingFactor();
        FFTFilteredEnum filteredEnum = globalFFTSettings.getFilteredEnum();
        addDropdown("bandPowerSmoothingDropdown", "Smooth", smoothingFactor.getEnumStringsAsList(), smoothingFactor.getIndex());
        addDropdown("bandPowerDataFilteringDropdown", "Filtered?", filteredEnum.getEnumStringsAsList(), filteredEnum.getIndex());

        // Setup for the BandPower plot
        bp_plot = new GPlot(_parent, x, y-navHeight, w, h+navHeight);
        // bp_plot.setPos(x, y+navHeight);
        bp_plot.setDim(w, h);
        bp_plot.setLogScale("y");
        bp_plot.setYLim(0.1, 100);
        bp_plot.setXLim(0, 5);
        bp_plot.getYAxis().setNTicks(9);
        bp_plot.getXAxis().setNTicks(0);
        bp_plot.getTitle().setTextAlignment(LEFT);
        bp_plot.getTitle().setRelativePos(0);
        bp_plot.setAllFontProperties("Arial", 0, 14);
        bp_plot.getYAxis().getAxisLabel().setText("Power — (uV)^2 / Hz");
        bp_plot.getXAxis().setAxisLabelText("EEG Power Bands");
        bp_plot.getXAxis().getAxisLabel().setOffset(42f);
        bp_plot.startHistograms(GPlot.VERTICAL);
        bp_plot.getHistogram().setDrawLabels(true);
        bp_plot.getXAxis().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getXAxis().setLineColor(OPENBCI_DARKBLUE);
        bp_plot.getXAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().setLineColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);

        //setting border of histograms to match BG
        bp_plot.getHistogram().setLineColors(new color[]{
            color(245), color(245), color(245), color(245), color(245)
          }
        );
        //setting bg colors of histogram bars to match the color scheme of the channel colors w/ an opacity of 150/255
        bp_plot.getHistogram().setBgColors(new color[] {
                color((int)channelColors[6], 200),
                color((int)channelColors[4], 200),
                color((int)channelColors[3], 200),
                color((int)channelColors[2], 200), 
                color((int)channelColors[1], 200),
            }
        );
        //setting color of text label for each histogram bar on the x axis
        bp_plot.getHistogram().setFontColor(OPENBCI_DARKBLUE);
    }

    public void update() {
        super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

        // If enabled, automatically turn channels on or off in ExGChannelSelect for this widget
        autoCleanByEnableDisableChannels();
        
        //Update channel checkboxes and active channels
        bpChanSelect.update(x, y, w);
        
        //Flex the Gplot graph when channel select dropdown is open/closed
        if (bpChanSelect.isVisible() != prevChanSelectIsVisible) {
            flexGPlotSizeAndPosition();
            prevChanSelectIsVisible = bpChanSelect.isVisible();
        }

        GPointsArray bp_points = new GPointsArray(dataProcessing.headWidePower.length);
        bp_points.add(DELTA + 0.5, activePower[DELTA], "DELTA\n0.5-4Hz");
        bp_points.add(THETA + 0.5, activePower[THETA], "THETA\n4-8Hz");
        bp_points.add(ALPHA + 0.5, activePower[ALPHA], "ALPHA\n8-13Hz");
        bp_points.add(BETA + 0.5, activePower[BETA], "BETA\n13-32Hz");
        bp_points.add(GAMMA + 0.5, activePower[GAMMA], "GAMMA\n32-100Hz");
        bp_plot.setPoints(bp_points);

        if (bpChanSelect.isVisible()) {
            lockElementsOnOverlapCheck(cp5ElementsToCheck);
        }
    }

    public void draw() {
        super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)
        pushStyle();

        //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        // Draw the third plot
        bp_plot.beginDraw();
        bp_plot.drawBackground();
        bp_plot.drawBox();
        bp_plot.drawXAxis();
        bp_plot.drawYAxis();
        bp_plot.drawGridLines(GPlot.HORIZONTAL);
        bp_plot.drawHistograms();
        bp_plot.endDraw();

        //for this widget need to redraw the grey bar, bc the FFT plot covers it up...
        fill(200, 200, 200);
        rect(x, y - navHeight, w, navHeight); //button bar

        popStyle();
        bpChanSelect.draw();
    }

    public void screenResized() {
        super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

        flexGPlotSizeAndPosition();

        bpChanSelect.screenResized(pApplet);
    }

    public void mousePressed() {
        super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)
        bpChanSelect.mousePressed(this.dropdownIsActive); //Calls channel select mousePressed and checks if clicked
    }

    void flexGPlotSizeAndPosition() {
        if (bpChanSelect.isVisible()) {
            bp_plot.setPos(x, y + bpChanSelect.getHeight() - navH);
            bp_plot.setOuterDim(w, h - bpChanSelect.getHeight() + navH);
        } else {
            bp_plot.setPos(x, y - navH);
            bp_plot.setOuterDim(w, h + navH);
        }
    }

    public float[] getNormalizedBPSelectedChannels() {
        return normalizedBandPowers;
    }

    private void autoCleanByEnableDisableChannels() {
        if (autoClean == BPAutoClean.OFF) {
            return;
        }

        int numChannels = currentBoard.getNumEXGChannels();
        for (int i = 0; i < numChannels; i++) {
            float uvrms = dataProcessing.data_std_uV[i];
            boolean thresholdCrossed = uvrms > autoCleanThreshold.getValue();

            int currentMillis = millis();

            //Check for state change. Reset timer on either state.
            if (thresholdCrossed != previousThresholdCrossed[i]) {
                previousThresholdCrossed[i] = thresholdCrossed;
                autoCleanTimers[i] = currentMillis;
            }
            
            //Auto-disable a channel if it's above the threshold and has been for the timer duration
            boolean timerDurationExceeded = currentMillis - autoCleanTimers[i] > autoCleanTimer.getValue();
            if (timerDurationExceeded) {
                boolean enableChannel = !thresholdCrossed;
                bpChanSelect.setToggleState(i, enableChannel);
            } 
        }
    }

    public BPAutoClean getAutoClean() {
        return autoClean;
    }

    public BPAutoCleanThreshold getAutoCleanThreshold() {
        return autoCleanThreshold;
    }

    public BPAutoCleanTimer getAutoCleanTimer() {
        return autoCleanTimer;
    }

    public void setAutoClean(int n) {
        autoClean = autoClean.values()[n];
        Arrays.fill(previousThresholdCrossed, false);
        Arrays.fill(autoCleanTimers, 0);
    }

    public void setAutoCleanThreshold(int n) {
        autoCleanThreshold = autoCleanThreshold.values()[n];
    }

    public void setAutoCleanTimer(int n) {
        autoCleanTimer = autoCleanTimer.values()[n];
    }

    //Called in DataProcessing.pde to update data even if widget is closed
    public void updateBandPowerWidgetData() {
        float normalizingSum = 0;

        for (int i = 0; i < NUM_BANDS; i++) {
            float sum = 0;
            for (int j = 0; j < bpChanSelect.getActiveChannels().size(); j++) {
                int chan = bpChanSelect.getActiveChannels().get(j);
                sum += dataProcessing.avgPowerInBins[chan][i];
            }
            activePower[i] = sum / bpChanSelect.getActiveChannels().size();
            normalizingSum += activePower[i];
        }

        for (int i = 0; i < NUM_BANDS; i++) {
            normalizedBandPowers[i] = activePower[i] / normalizingSum;
        }
    }
};

public void bandPowerAutoCleanDropdown(int n) {
    w_bandPower.setAutoClean(n);
}

public void bandPowerAutoCleanThresholdDropdown(int n) {
    w_bandPower.setAutoCleanThreshold(n);
}

public void bandPowerAutoCleanTimerDropdown(int n) {
    w_bandPower.setAutoCleanTimer(n);
}

public void bandPowerSmoothingDropdown(int n) {
    globalFFTSettings.setSmoothingFactor(FFTSmoothingFactor.values()[n]);
    //FIX ME TO UPDATE THE FFT WIDGET DROPDOWN ALSO
}

public void bandPowerDataFilteringDropdown(int n) {
    globalFFTSettings.setFilteredEnum(FFTFilteredEnum.values()[n]);
    //FIX ME TO UPDATE THE FFT WIDGET DROPDOWN ALSO
}