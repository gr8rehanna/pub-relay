pub mod apub;
mod deliver;
mod deliver_many;
mod instance;
mod nodeinfo;
mod process_listeners;
mod storage;

pub use self::{
    deliver::Deliver, deliver_many::DeliverMany, instance::QueryInstance, nodeinfo::QueryNodeinfo,
};

use crate::{
    config::Config,
    data::{ActorCache, Media, NodeCache, State},
    db::Db,
    error::MyError,
    jobs::{process_listeners::Listeners, storage::Storage},
    requests::Requests,
};
use background_jobs::{Job, QueueHandle, WorkerConfig};
use std::time::Duration;

pub fn create_server(db: Db) -> JobServer {
    let shared = background_jobs::create_server(Storage::new(db));

    shared.every(Duration::from_secs(60 * 5), Listeners);

    JobServer::new(shared)
}

pub fn create_workers(
    db: Db,
    state: State,
    actors: ActorCache,
    job_server: JobServer,
    media: Media,
    config: Config,
) {
    let remote_handle = job_server.remote.clone();

    WorkerConfig::new(move || {
        JobState::new(
            db.clone(),
            state.clone(),
            actors.clone(),
            job_server.clone(),
            media.clone(),
            config.clone(),
        )
    })
    .register::<Deliver>()
    .register::<Deliver>()
    .register::<QueryNodeinfo>()
    .register::<QueryInstance>()
    .register::<Listeners>()
    .register::<apub::Announce>()
    .register::<apub::Follow>()
    .register::<apub::Forward>()
    .register::<apub::Reject>()
    .register::<apub::Undo>()
    .set_worker_count("default", 4)
    .start(remote_handle);
}

#[derive(Clone)]
pub struct JobState {
    db: Db,
    requests: Requests,
    state: State,
    actors: ActorCache,
    config: Config,
    media: Media,
    node_cache: NodeCache,
    job_server: JobServer,
}

#[derive(Clone)]
pub struct JobServer {
    remote: QueueHandle,
}

impl JobState {
    fn new(
        db: Db,
        state: State,
        actors: ActorCache,
        job_server: JobServer,
        media: Media,
        config: Config,
    ) -> Self {
        JobState {
            requests: state.requests(),
            node_cache: state.node_cache(),
            db,
            actors,
            config,
            media,
            state,
            job_server,
        }
    }
}

impl JobServer {
    fn new(remote_handle: QueueHandle) -> Self {
        JobServer {
            remote: remote_handle,
        }
    }

    pub fn queue<J>(&self, job: J) -> Result<(), MyError>
    where
        J: Job,
    {
        self.remote.queue(job).map_err(MyError::Queue)
    }
}
