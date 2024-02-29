use lambda_runtime::{service_fn, LambdaEvent, Error};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tracing::info;
use tracing_subscriber::EnvFilter;
use rust_lambda::lambda_handler;

#[derive(Serialize, Deserialize, Debug)]
struct MyPayload {
    first_name: String,
}

impl Default for MyPayload {
    fn default() -> Self {
        MyPayload {
            first_name: "world".to_string(),
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_lambda_tracing();
    let func = service_fn(func);
    lambda_runtime::run(func).await?;
    Ok(())
}

// This is the Lambda function
async fn func(event: LambdaEvent<lambda_handler::LambdaProxyEvent>) -> Result<Value, Error> {
    let (event, _context) = event.into_parts();
    info!("Received event: {:?}", event);
    let body = event.body.unwrap_or_default();
    info!("Received body: {:?}", body);
    let payload: MyPayload = serde_json::from_str(&body).unwrap_or_default();
    info!("Received payload: {:?}", payload);
    // Return the Ok response with the payload
    Ok(json!(payload))
}

fn init_lambda_tracing() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        // .with_max_level(tracing::Level::INFO)
        // this needs to be set to false, otherwise ANSI color codes will
        // show up in a confusing manner in CloudWatch logs.
        .with_ansi(false)
        // disabling time is handy because CloudWatch will add the ingestion time.
        .without_time()
        .init();
}