
public enum EmgJoystickSmoothing implements IndexingInterface
{
    OFF (0, "Off", 0f),
    POINT_9 (1, "0.9", .9f),
    POINT_95 (2, "0.95", .95f),
    POINT_98 (3, "0.98", .98f),
    POINT_99 (4, "0.99", .99f),
    POINT_999 (5, "0.999", .999f),
    POINT_9999 (6, "0.9999", .9999f);

    private int index;
    private String name;
    private float value;
    private static EmgJoystickSmoothing[] vals = values();
 
    EmgJoystickSmoothing(int index, String name, float value) {
        this.index = index;
        this.name = name;
        this.value = value;
    }

    public int getIndex() {
        return index;
    }
    
    public String getString() {
        return name;
    }

    public float getValue() {
        return value;
    }

    private static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<String>();
        for (IndexingInterface val : vals) {
            enumStrings.add(val.getString());
        }
        return enumStrings;
    }
}

public class EMGJoystickInput {
    private int index;
    private String name;
    private int value;
    
    EMGJoystickInput(int index, String name, int value) {
        this.index = index;
        this.name = name;
        this.value = value;
    }

    public int getIndex() {
        return index;
    }

    public String getString() {
        return name;
    }

    public int getValue() {
        return value;
    }
}

public class EMGJoystickInputs {
    private final int NUM_EMG_INPUTS = 4;
    private final EMGJoystickInput[] VALUES;
    private final EMGJoystickInput[] INPUTS = new EMGJoystickInput[NUM_EMG_INPUTS];

    EMGJoystickInputs(int numExGChannels) {
        VALUES = new EMGJoystickInput[numExGChannels];
        for (int i = 0; i < numExGChannels; i++) {
            VALUES[i] = new EMGJoystickInput(i, "Channel " + (i + 1), i);
        }
    }

    public EMGJoystickInput[] getValues() {
        return VALUES;
    }

    public EMGJoystickInput[] getInputs() {
        return INPUTS;
    }

    public EMGJoystickInput getInput(int index) {
        return INPUTS[index];
    }

    public void setInputToChannel(int inputNumber, int channel) {
        if (inputNumber < 0 || inputNumber >= NUM_EMG_INPUTS) {
            println("Invalid input number: " + inputNumber);
            return;
        }
        if (channel < 0 || channel >= VALUES.length) {
            println("Invalid channel: " + channel);
            return;
        }
        INPUTS[inputNumber] = VALUES[channel];
    }

    public List<String> getValueStringsAsList() {
        List<String> enumStrings = new ArrayList<String>();
        for (EMGJoystickInput val : VALUES) {
            enumStrings.add(val.getString());
        }
        return enumStrings;
    }
}