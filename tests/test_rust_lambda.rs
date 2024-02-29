use reqwest::Client;
use serde_json::{Value, json};
use std::env;
use tokio;

#[tokio::test]
async fn test_post_endpoint() {
    let client = Client::new();

    // Retrieve the URL from the LAMBDA_INVOKE_URL environment variable
    let url = env::var("LAMBDA_INVOKE_URL")
        .expect("LAMBDA_INVOKE_URL environment variable not set");

    let request_body = json!({
        "first_name": "Rustacean"
    });

    // Send a POST request
    let response = client.post(&url)
        .json(&request_body)
        .send()
        .await
        .expect("Failed to execute request.");

    // Assert the status code
    assert_eq!(response.status(), reqwest::StatusCode::OK);

    // Parse the response body to JSON
    let response_body: Value = response.json().await.expect("Failed to parse JSON");

    // Assert the response body is as expected
    assert_eq!(response_body, request_body);
}