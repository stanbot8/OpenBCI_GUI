//////////////////////////////////////////////////////
//                                                  //
//                  W_Spectrogram.pde               //
//                                                  //
//                                                  //
//    Created by: Richard Waltman, September 2019   //
//                                                  //
//////////////////////////////////////////////////////

class W_Spectrogram extends Widget {
    //to see all core variables/methods of the Widget class, refer to Widget.pde
    public ExGChannelSelect spectChanSelectTop;
    public ExGChannelSelect spectChanSelectBot;
    private boolean chanSelectWasOpen = false;
    List<controlP5.Controller> cp5ElementsToCheck = new ArrayList<controlP5.Controller>();

    int xPos = 0;
    int hueLimit = 160;

    PImage dataImg;
    int dataImageW = 1800;
    int dataImageH = 200;
    int prevW = 0;
    int prevH = 0;
    float scaledWidth;
    float scaledHeight;
    int graphX = 0;
    int graphY = 0;
    int graphW = 0;
    int graphH = 0;
    int midLineY = 0;

    private int lastShift = 0;
    private int scrollSpeed = 25; // == 40Hz
    private boolean wasRunning = false;

    int paddingLeft = 54;
    int paddingRight = 26;   
    int paddingTop = 8;
    int paddingBottom = 50;
    StringList horizontalAxisLabelStrings;

    float[] topFFTAvg;
    float[] botFFTAvg;

    private SpectrogramMaxFrequency maxFrequency = SpectrogramMaxFrequency.MAX_60;
    private SpectrogramWindowSize windowSize = SpectrogramWindowSize.ONE_MINUTE;
    private FFTLogLin logLin = FFTLogLin.LIN;

    W_Spectrogram() {
        super();
        widgetTitle = "Spectrogram";

        //Add channel select dropdown to this widget
        spectChanSelectTop = new DualExGChannelSelect(ourApplet, x, y, w, navH, true);
        spectChanSelectBot = new DualExGChannelSelect(ourApplet, x, y + navH, w, navH, false);
        activateDefaultChannels();

        cp5ElementsToCheck.addAll(spectChanSelectTop.getCp5ElementsForOverlapCheck());
        cp5ElementsToCheck.addAll(spectChanSelectBot.getCp5ElementsForOverlapCheck());

        xPos = w - 1; //draw on the right, and shift pixels to the left
        prevW = w;
        prevH = h;
        graphX = x + paddingLeft;
        graphY = y + paddingTop;
        graphW = w - paddingRight - paddingLeft;
        graphH = h - paddingBottom - paddingTop;
        
        //Fetch/calculate the time strings for the horizontal axis ticks
        horizontalAxisLabelStrings = fetchTimeStrings();

        List<String> maxFrequencyList = EnumHelper.getEnumStrings(SpectrogramMaxFrequency.class);
        List<String> windowSizeList = EnumHelper.getEnumStrings(SpectrogramWindowSize.class);
        List<String> logLinList = EnumHelper.getEnumStrings(FFTLogLin.class);

        addDropdown("spectrogramMaxFrequencyDropdown", "Max Hz", maxFrequencyList, maxFrequency.getIndex());
        addDropdown("spectrogramWindowDropdown", "Window", windowSizeList, windowSize.getIndex());
        addDropdown("spectrogramLogLinDropdown", "Log/Lin", logLinList, logLin.getIndex());

        //Resize the height of the data image using default 
        dataImageH = maxFrequency.getAxisLabels()[0] * 2;
        //Create image using correct dimensions! Fixes bug where image size and labels do not align on session start.
        dataImg = createImage(dataImageW, dataImageH, RGB);
    }

    void update(){
        super.update();

        //Update channel checkboxes, active channels, and position
        spectChanSelectTop.update(x, y, w);
        int chanSelectBotYOffset;
        chanSelectBotYOffset = navH;
        spectChanSelectBot.update(x, y + chanSelectBotYOffset, w);
        
        //Let the top channel select open the bottom one also so we can open both with 1 button
        if (chanSelectWasOpen != spectChanSelectTop.isVisible()) {
            spectChanSelectBot.setIsVisible(spectChanSelectTop.isVisible());
            chanSelectWasOpen = spectChanSelectTop.isVisible();
        }

        //Allow spectrogram to flex size and position depending on if the channel select is open
        flexSpectrogramSizeAndPosition();

        if (spectChanSelectTop.isVisible()) {
            lockElementsOnOverlapCheck(cp5ElementsToCheck);
        }
        
        if (currentBoard.isStreaming()) {
            //Make sure we are always draw new pixels on the right
            xPos = dataImg.width - 1;
            //Fetch/calculate the time strings for the horizontal axis ticks
            horizontalAxisLabelStrings.clear();
            horizontalAxisLabelStrings = fetchTimeStrings();
        }
        
        //State change check
        if (currentBoard.isStreaming() && !wasRunning) {
            onStartRunning();
        } else if (!currentBoard.isStreaming() && wasRunning) {
            onStopRunning();
        }
    }

    private void onStartRunning() {
        wasRunning = true;
        lastShift = millis();
    }

    private void onStopRunning() {
        wasRunning = false;
    }

    public void draw(){
        super.draw();

        //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        
        //Scale the dataImage to fit in inside the widget
        float scaleW = float(graphW) / dataImageW;
        float scaleH = float(graphH) / dataImageH;

        pushStyle();
        fill(0);
        rect(x, y, w, h); //draw a black background for the widget
        popStyle();

        //draw the spectrogram if the widget is open, and update pixels if board is streaming data
        if (currentBoard.isStreaming()) {
            pushStyle();
            dataImg.loadPixels();

            //Shift all pixels to the left! (every scrollspeed ms)
            if(millis() - lastShift > scrollSpeed) {
                for (int r = 0; r < dataImg.height; r++) {
                    if (r != 0) {
                        arrayCopy(dataImg.pixels, dataImg.width * r, dataImg.pixels, dataImg.width * r - 1, dataImg.width);
                    } else {
                        //When there would be an ArrayOutOfBoundsException, account for it!
                        arrayCopy(dataImg.pixels, dataImg.width * (r + 1), dataImg.pixels, r * dataImg.width, dataImg.width);
                    }
                }

                lastShift += scrollSpeed;
            }
            //for (int i = 0; i < fftLin_L.specSize() - 80; i++) {
            for (int i = 0; i <= dataImg.height/2; i++) {
                //LEFT SPECTROGRAM ON TOP
                float hueValue = hueLimit - map((fftAvgs(spectChanSelectTop.getActiveChannels(), i)*32), 0, 256, 0, hueLimit);
                if (logLin == FFTLogLin.LOG) {
                    hueValue = map(log10(hueValue), 0, 2, 0, hueLimit);
                }
                // colorMode is HSB, the range for hue is 256, for saturation is 100, brightness is 100.
                colorMode(HSB, 256, 100, 100);
                // color for stroke is specified as hue, saturation, brightness.
                stroke(int(hueValue), 100, 80);
                // plot a point using the specified stroke
                //point(xPos, i);
                int loc = xPos + ((dataImg.height/2 - i) * dataImg.width);
                if (loc >= dataImg.width * dataImg.height) loc = dataImg.width * dataImg.height - 1;
                try {
                    dataImg.pixels[loc] = color(int(hueValue), 100, 80);
                } catch (Exception e) {
                    println("Major drawing error Spectrogram Left image!");
                }

                //RIGHT SPECTROGRAM ON BOTTOM
                hueValue = hueLimit - map((fftAvgs(spectChanSelectBot.getActiveChannels(), i)*32), 0, 256, 0, hueLimit);
                if (logLin == FFTLogLin.LOG) {
                    hueValue = map(log10(hueValue), 0, 2, 0, hueLimit);
                }
                // colorMode is HSB, the range for hue is 256, for saturation is 100, brightness is 100.
                colorMode(HSB, 256, 100, 100);
                // color for stroke is specified as hue, saturation, brightness.
                stroke(int(hueValue), 100, 80);
                int y_offset = -1;
                // Pixel = X + ((Y + Height/2) * Width)
                loc = xPos + ((i + dataImg.height/2 + y_offset) * dataImg.width);
                if (loc >= dataImg.width * dataImg.height) loc = dataImg.width * dataImg.height - 1;
                try {
                    dataImg.pixels[loc] = color(int(hueValue), 100, 80);
                } catch (Exception e) {
                    println("Major drawing error Spectrogram Right image!");
                }
            }
            dataImg.updatePixels();
            popStyle();
        }
        
        pushMatrix();
        translate(graphX, graphY);
        scale(scaleW, scaleH);
        image(dataImg, 0, 0);
        popMatrix();

        spectChanSelectTop.draw();
        spectChanSelectBot.draw();
        drawAxes(scaleW, scaleH);
        drawCenterLine();
    }

    public void screenResized(){
        super.screenResized();

        spectChanSelectTop.screenResized(ourApplet);
        spectChanSelectBot.screenResized(ourApplet);  
        graphX = x + paddingLeft;
        graphY = y + paddingTop;
        graphW = w - paddingRight - paddingLeft;
        graphH = h - paddingBottom - paddingTop;
    }

    void mousePressed(){
        super.mousePressed();

        spectChanSelectTop.mousePressed(this.dropdownIsActive); //Calls channel select mousePressed and checks if clicked
        spectChanSelectBot.mousePressed(this.dropdownIsActive);
    }

    void mouseReleased(){
        super.mouseReleased();

    }

    void drawAxes(float scaledW, float scaledH) {
        
        pushStyle();
            fill(255);
            textSize(14);
            //draw horizontal axis label
            text("Time", x + w/2 - textWidth("Time")/3, y + h - 9);
            noFill();
            stroke(255);
            strokeWeight(2);
            //draw rectangle around the spectrogram
            rect(graphX, graphY, scaledW * dataImageW, scaledH * dataImageH);
        popStyle();

        pushStyle();
            //draw horizontal axis ticks from left to right
            int tickMarkSize = 7; //in pixels
            float horizontalAxisX = graphX;
            float horizontalAxisY = graphY + scaledH * dataImageH;
            stroke(255);
            fill(255);
            strokeWeight(2);
            textSize(11);
            int horizontalAxisDivCount = windowSize.getAxisLabels().length;
            for (int i = 0; i < horizontalAxisDivCount; i++) {
                float offset = scaledW * dataImageW * (float(i) / horizontalAxisDivCount);
                line(horizontalAxisX + offset, horizontalAxisY, horizontalAxisX + offset, horizontalAxisY + tickMarkSize);
                if (horizontalAxisLabelStrings.get(i) != null) {
                    text(horizontalAxisLabelStrings.get(i), horizontalAxisX + offset - (int)textWidth(horizontalAxisLabelStrings.get(i))/2, horizontalAxisY + tickMarkSize * 3);
                }
            }
        popStyle();
        
        pushStyle();
            pushMatrix();
                rotate(radians(-90));
                textSize(14);
                int yAxisLabelOffset = spectChanSelectTop.isVisible() ? (int)textWidth("Frequency (Hz)") / 4 : 0;
                translate(-h/2 - textWidth("Frequency (Hz)")/4, 20);
                fill(255);
                // Draw y axis label only when channel select is not visible due to overlap
                if (!spectChanSelectTop.isVisible()) {
                    text("Frequency (Hz)", -y - yAxisLabelOffset, x);
                }
            popMatrix();
        popStyle();

        pushStyle();
            //draw vertical axis ticks from top to bottom
            float verticalAxisX = graphX;
            float verticalAxisY = graphY;
            stroke(255);
            fill(255);
            textSize(12);
            strokeWeight(2);
            int verticalAxisDivCount = maxFrequency.getAxisLabels().length - 1;
            for (int i = 0; i < verticalAxisDivCount; i++) {
                float offset = scaledH * dataImageH * (float(i) / verticalAxisDivCount);
                //if (i <= verticalAxisDivCount/2) offset -= 2;
                line(verticalAxisX, verticalAxisY + offset, verticalAxisX - tickMarkSize, verticalAxisY + offset);
                if (maxFrequency.getAxisLabels()[i] == 0) midLineY = int(verticalAxisY + offset);
                offset += paddingTop/2;
                text(maxFrequency.getAxisLabels()[i], verticalAxisX - tickMarkSize*2 - textWidth(Integer.toString(maxFrequency.getAxisLabels()[i])), verticalAxisY + offset);
            }
        popStyle();

        drawColorScaleReference();
    }

    void drawCenterLine() {
        //draw a thick line down the middle to separate the two plots
        pushStyle();
        stroke(255);
        strokeWeight(3);
        line(graphX, midLineY, graphX + graphW, midLineY);
        popStyle();
    }

    void drawColorScaleReference() {
        int colorScaleHeight = 128;
        //Dynamically scale the Log/Lin amplitude-to-color reference line. If it won't fit, don't draw it.
        if (graphH < colorScaleHeight) {
            colorScaleHeight = int(h * 1/2);
            if (colorScaleHeight > graphH) {
                return;
            }
        }
        pushStyle();
            //draw color scale reference to the right of the spectrogram
            for (int i = 0; i < colorScaleHeight; i++) {
                float hueValue = hueLimit - map(i * 2, 0, colorScaleHeight*2, 0, hueLimit);
                if (logLin == FFTLogLin.LOG) {
                    hueValue = map(log(hueValue) / log(10), 0, 2, 0, hueLimit);
                }
                //println(hueValue);
                // colorMode is HSB, the range for hue is 256, for saturation is 100, brightness is 100.
                colorMode(HSB, 256, 100, 100);
                // color for stroke is specified as hue, saturation, brightness.
                stroke(ceil(hueValue), 100, 80);
                strokeWeight(10);
                point(x + w - paddingRight/2 + 1, midLineY + colorScaleHeight/2 - i);
            }
        popStyle();
    }

    void activateDefaultChannels() {
        int[] topChansToActivate;
        int[] botChansToActivate; 

        if (globalChannelCount == 4) {
            topChansToActivate = new int[]{0, 2};
            botChansToActivate = new int[]{1, 3};
        } else if (globalChannelCount == 8) {
            topChansToActivate = new int[]{0, 2, 4, 6};
            botChansToActivate = new int[]{1, 3, 5, 7};
        } else {
            topChansToActivate = new int[]{0, 2, 4, 6, 8 ,10, 12, 14};
            botChansToActivate = new int[]{1, 3, 5, 7, 9, 11, 13, 15};
        }

        for (int i = 0; i < topChansToActivate.length; i++) {
            spectChanSelectTop.setToggleState(topChansToActivate[i], true);
            
        }

        for (int i = 0; i < botChansToActivate.length; i++) {
            spectChanSelectBot.setToggleState(botChansToActivate[i], true);
        }
    }

    void flexSpectrogramSizeAndPosition() {
        int flexHeight = spectChanSelectTop.getHeight() + spectChanSelectBot.getHeight();
        if (spectChanSelectTop.isVisible()) {
            graphY = y + paddingTop + flexHeight;
            graphH = h - paddingBottom - paddingTop - flexHeight;
        } else {
            graphY = y + paddingTop;
            graphH = h - paddingBottom - paddingTop;
        }
    }

    void setScrollSpeed(int i) {
        scrollSpeed = i;
    }

    float fftAvgs(List<Integer> _activeChan, int freqBand) {
        float sum = 0f;
        for (int i = 0; i < _activeChan.size(); i++) {
            sum += fftBuff[_activeChan.get(i)].getBand(freqBand);
        }
        return sum / _activeChan.size();
    }

    private StringList fetchTimeStrings() {
        StringList output = new StringList();
        LocalDateTime time;
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm:ss");
        if (getCurrentTimeStamp() == 0) {
            time = LocalDateTime.now();
        } else {
            time = LocalDateTime.ofInstant(Instant.ofEpochMilli(getCurrentTimeStamp()), 
                                            TimeZone.getDefault().toZoneId()); 
        }
        for (int i = 0; i < windowSize.getAxisLabels().length; i++) {
            long l = (long)(windowSize.getAxisLabels()[i] * 60f);
            LocalDateTime t = time.minus(l, ChronoUnit.SECONDS);
            output.append(t.format(formatter));
        }
        return output;
    }

    //Identical to the method in TimeSeries, but allows spectrogram to get the data directly from the playback data in the background
    //Find times to display for playback position
    private long getCurrentTimeStamp() {
        //return current playback time
        List<double[]> currentData = currentBoard.getData(1);
        if (currentData.size() == 0 || currentData.get(0).length == 0) {
            return 0;
        }
        int timeStampChan = currentBoard.getTimestampChannel();
        long timestampMS = (long)(currentData.get(0)[timeStampChan] * 1000.0);
        return timestampMS;
    }

    public void clear() {
        // Set all pixels to black (or any other background color you want to clear with)
        for (int i = 0; i < dataImg.pixels.length; i++) {
            dataImg.pixels[i] = color(0);  // Black background
        }
    }

    public void setLogLin(int n) {
        logLin = logLin.values()[n];
    }

    public void setMaxFrequency(int n) {
        maxFrequency = maxFrequency.values()[n];
        // Resize the height of the data image
        dataImageH = maxFrequency.getAxisLabels()[0] * 2;
        // Overwrite the existing image
        dataImg = createImage(dataImageW, dataImageH, RGB);
    }

    public void setWindowSize(int n) {
        windowSize = windowSize.values()[n];
        setScrollSpeed(windowSize.getScrollSpeed());
        horizontalAxisLabelStrings.clear();
        horizontalAxisLabelStrings = fetchTimeStrings();
        dataImg = createImage(dataImageW, dataImageH, RGB);

    }
};

public void spectrogramMaxFrequencyDropdown(int n) {
    ((W_Spectrogram) widgetManager.getWidget("W_Spectrogram")).setMaxFrequency(n);
}

public void spectrogramWindowDropdown(int n) {
    ((W_Spectrogram) widgetManager.getWidget("W_Spectrogram")).setWindowSize(n);
}

public void spectrogramLogLinDropdown(int n) {
    ((W_Spectrogram) widgetManager.getWidget("W_Spectrogram")).setLogLin(n);
}