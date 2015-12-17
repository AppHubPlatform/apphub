package io.apphub;

public enum AppHubLogLevel {
    NONE(0),
    DEBUG(1),
    WARNING(2),
    ERROR(3);

    private int value;

    private AppHubLogLevel(int value) {
        this.value = value;
    }

    protected int getValue() {
        return value;
    }

    protected String getStringValue() {
        switch (this.getValue()) {
            case 0:
                return "";
            case 1:
                return "DEBUG";
            case 2:
                return "WARNING";
            case 3:
                return "ERROR";
            default:
                throw new UnsupportedOperationException();
        }
    }
}
