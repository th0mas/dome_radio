use rodio::{OutputStream, OutputStreamHandle, Sink, Source};
use rustler::{Env, ResourceArc, Term};

use std::io::BufReader;
use std::sync::Mutex;

struct StreamHandles{
    pub _stream: OutputStream,
    pub handle: OutputStreamHandle

}

struct Container {
    pub mux: Mutex<StreamHandles>,
}

struct AudioStream {
    sink: Sink
}

// Trust me bro
unsafe impl Send for StreamHandles {}

fn load(env: Env, _: Term) -> bool {
    rustler::resource!(Container, env);
    rustler::resource!(AudioStream, env);
    true
}

#[rustler::nif]
fn start() -> ResourceArc<Container> {
    let (stream, handle) = OutputStream::try_default().unwrap();

    ResourceArc::new(Container {
        mux: Mutex::new(StreamHandles {
            _stream: stream,
            handle,
        }),
    })
}

#[rustler::nif]
fn play_file(handles: ResourceArc<Container>, file_path: &str) -> ResourceArc<AudioStream>{
    let handle = &handles.mux.try_lock().unwrap().handle;
    let file = std::fs::File::open(file_path).unwrap();
    let audio = rodio::Decoder::new(BufReader::new(file)).unwrap().repeat_infinite();
    
    let sink = rodio::Sink::try_new(handle).unwrap();
    sink.append(audio);

    ResourceArc::new(AudioStream {
        sink
    })
}

#[rustler::nif]
fn set_stream_parameters(stream: ResourceArc<AudioStream>, speed: f32, volume: f32) -> ResourceArc<AudioStream>{
    stream.sink.set_speed(speed);
    stream.sink.set_volume(volume);

    stream
}



rustler::init!("Elixir.AudioBridge", [start, play_file, set_stream_parameters], load = load);
