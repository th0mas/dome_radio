use rodio::{OutputStream, OutputStreamHandle, Sink, Source};
use rustler::{Env, Error, ResourceArc, Term};

use std::io::BufReader;
use std::sync::{Arc, Mutex};

mod atoms {
    rustler::atoms! {
        ok,
        error,

        failed_to_start
    }
}

struct StreamHandles {
    pub handle: OutputStreamHandle,
    _stream: Arc<OutputStream>
}

struct Container{
    pub mux: Mutex<StreamHandles>,
}

struct AudioStream {
    sink: Sink,
}

// Trust me bro
unsafe impl Send for StreamHandles {}

fn load(env: Env, _: Term) -> bool {
    rustler::resource!(Container, env);
    rustler::resource!(AudioStream, env);
    true
}

#[rustler::nif]
fn start() -> Result<ResourceArc<Container>, Error> {
    let result = OutputStream::try_default();
    match result {
        Ok((stream, handle)) => Ok(ResourceArc::new(Container {
            mux: Mutex::new(StreamHandles {
                _stream: Arc::new(stream),
                handle,
            }),
        })),
        Err(_) => Err(Error::Term(Box::new(atoms::failed_to_start()))),
    }
}

#[rustler::nif]
fn play_file(handles: ResourceArc<Container>, file_path: &str) -> ResourceArc<AudioStream> {
    let handle = &handles.mux.lock().unwrap().handle;
    let file = std::fs::File::open(file_path).unwrap();
    let audio = rodio::Decoder::new(BufReader::new(file))
        .unwrap()
        .repeat_infinite();

    let sink = rodio::Sink::try_new(handle).unwrap();
    sink.append(audio);

    ResourceArc::new(AudioStream { sink })
}

#[rustler::nif]
fn set_stream_parameters(
    stream: ResourceArc<AudioStream>,
    speed: f32,
    volume: f32,
) -> ResourceArc<AudioStream> {
    stream.sink.set_speed(speed);
    stream.sink.set_volume(volume);

    stream
}


rustler::init!(
    "Elixir.AudioBridge",
    [start, play_file, set_stream_parameters],
    load = load
);
