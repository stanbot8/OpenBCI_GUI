
////////////////////////////////////////////////////
//
//    W_Template.pde (ie "Widget Template")
//
//    This is a Template Widget, intended to be used as a starting point for OpenBCI Community members that want to develop their own custom widgets!
//    Good luck! If you embark on this journey, please let us know. Your contributions are valuable to everyone!
//
//    Created by: Conor Russomanno, November 2016
//
///////////////////////////////////////////////////,

class W_Template extends Widget {

    //to see all core variables/methods of the Widget class, refer to Widget.pde
    //put your custom variables here...
    ControlP5 localCP5;
    Button widgetTemplateButton;

    W_Template(String _widgetName) {
        super(_widgetName);
        
        //This is the protocol for setting up dropdowns.
        //Note that these 3 dropdowns correspond to the 3 global functions below
        //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function
        addDropdown("Dropdown1", "Drop 1", Arrays.asList("A", "B"), 0);
        addDropdown("Dropdown2", "Drop 2", Arrays.asList("C", "D", "E"), 1);
        addDropdown("Dropdown3", "Drop 3", Arrays.asList("F", "G", "H", "I"), 3);


        //Instantiate local cp5 for this box. This allows extra control of drawing cp5 elements specifically inside this class.
        localCP5 = new ControlP5(ourApplet);
        localCP5.setGraphics(ourApplet, 0,0);
        localCP5.setAutoDraw(false);

        createWidgetTemplateButton();
       
    }

    public void update(){
        super.update();

        //put your code here...
    }

    public void draw(){
        super.draw();

        //remember to refer to x,y,w,h which are the positioning variables of the Widget class

        //This draws all cp5 objects in the local instance
        localCP5.draw();
    }

    public void screenResized(){
        super.screenResized();

        //Very important to allow users to interact with objects after app resize        
        localCP5.setGraphics(ourApplet, 0, 0);

        //We need to set the position of our Cp5 object after the screen is resized
        widgetTemplateButton.setPosition(x + w/2 - widgetTemplateButton.getWidth()/2, y + h/2 - widgetTemplateButton.getHeight()/2);

    }

    public void mousePressed(){
        super.mousePressed();
        //Since GUI v5, these methods should not really be used.
        //Instead, use ControlP5 objects and callbacks. 
        //Example: createWidgetTemplateButton() found below
    }

    public void mouseReleased(){
        super.mouseReleased();
        //Since GUI v5, these methods should not really be used.
    }

    //When creating new UI objects, follow this rough pattern.
    //Using custom methods like this allows us to condense the code required to create new objects.
    //You can find more detailed examples in the Control Panel, where there are many UI objects with varying functionality.
    private void createWidgetTemplateButton() {
        //This is a generalized createButton method that allows us to save code by using a few patterns and method overloading
        widgetTemplateButton = createButton(localCP5, "widgetTemplateButton", "Design Your Own Widget!", x + w/2, y + h/2, 200, NAV_HEIGHT, p4, 14, colorNotPressed, OPENBCI_DARKBLUE);
        //Set the border color explicitely
        widgetTemplateButton.setBorderColor(OBJECT_BORDER_GREY);
        //For this button, only call the callback listener on mouse release
        widgetTemplateButton.onRelease(new CallbackListener() {
            public void controlEvent(CallbackEvent theEvent) {
                //If using a TopNav object, ignore interaction with widget object (ex. widgetTemplateButton)
                if (!topNav.configSelector.isVisible && !topNav.layoutSelector.isVisible) {
                    openURLInBrowser("https://docs.openbci.com/Software/OpenBCISoftware/GUIWidgets/#custom-widget");
                }
            }
        });
        widgetTemplateButton.setDescription("Here is the description for this UI object. It will fade in as help text when hovering over the object.");
    }

    //add custom functions here
    private void customFunction(){
        //this is a fake function... replace it with something relevant to this widget

    }

};

/**
These functions (e.g. Dropdown1()) are global! They are activated when an item from the 
corresponding dropdown is selected. While it's true they could be defined in the class above 
with a CallbackListener, it's not worth the trouble (and the sheer amount of duplicated code)
for this specific kind of dropdown in each widget. In some widgets, you will see that we simply
use these global methods to call a method in the widget class. This is the best pattern to follow
due to the limitations of the ControlP5 library.
**/
void Dropdown1(int n){
    println("Item " + (n+1) + " selected from Dropdown 1");
    if(n==0){
        //do this
    } else if(n==1){
        //do this instead
    }
}

void Dropdown2(int n){
    println("Item " + (n+1) + " selected from Dropdown 2");
}

void Dropdown3(int n){
    println("Item " + (n+1) + " selected from Dropdown 3");
}
