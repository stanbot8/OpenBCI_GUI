import brainflow.*;

interface BrainFlowStream {
    void startStream(int bufferSize, String streamer) throws Exception;
    void stopStream() throws Exception;
    void deleteStreamerIfPresent(String streamer) throws Exception;
}

class BoardShimBrainFlowStream implements BrainFlowStream {
    private final BoardShim boardShim;

    BoardShimBrainFlowStream(BoardShim boardShim) {
        this.boardShim = boardShim;
    }

    public void startStream(int bufferSize, String streamer) throws BrainFlowError {
        boardShim.start_stream(bufferSize, streamer);
    }

    public void stopStream() throws BrainFlowError {
        try {
            boardShim.stop_stream();
        } catch (BrainFlowError error) {
            if (error.exit_code != BrainFlowExitCode.STREAM_THREAD_IS_NOT_RUNNING.get_code()) {
                throw error;
            }
        }
    }

    public void deleteStreamerIfPresent(String streamer) throws BrainFlowError {
        try {
            boardShim.delete_streamer(streamer);
        } catch (BrainFlowError error) {
            if (error.exit_code != BrainFlowExitCode.INVALID_ARGUMENTS_ERROR.get_code()) {
                throw error;
            }
        }
    }
}

class BrainFlowStreamerLifecycle {
    private static final int BUFFER_SIZE = 450000;

    private final BrainFlowStream stream;
    private String registeredStreamer = "";
    private boolean startIncomplete = false;
    private boolean streaming = false;

    BrainFlowStreamerLifecycle(BrainFlowStream stream) {
        this.stream = stream;
    }

    public void start(String streamer) throws Exception {
        if (streaming) {
            return;
        }

        cleanupIncompleteStart();
        removeRegisteredStreamer();
        registeredStreamer = streamer == null ? "" : streamer;
        startIncomplete = true;
        try {
            stream.startStream(BUFFER_SIZE, registeredStreamer);
            streaming = true;
            startIncomplete = false;
        } catch (Exception startError) {
            try {
                cleanupIncompleteStart();
            } catch (Exception cleanupError) {
                startError.addSuppressed(cleanupError);
            }
            throw startError;
        }
    }

    public void stop() throws Exception {
        if (!streaming) {
            return;
        }

        stream.stopStream();
        streaming = false;
        removeRegisteredStreamer();
    }

    public boolean isStreaming() {
        return streaming;
    }

    private void cleanupIncompleteStart() throws Exception {
        if (!startIncomplete) {
            return;
        }

        stream.stopStream();
        removeRegisteredStreamer();
        startIncomplete = false;
    }

    private void removeRegisteredStreamer() throws Exception {
        if (registeredStreamer.isEmpty()) {
            return;
        }

        stream.deleteStreamerIfPresent(registeredStreamer);
        registeredStreamer = "";
    }
}
