pub mod lambda_handler {
    use std::collections::BTreeMap;
    use serde::{Deserialize, Serialize};

    #[derive(Serialize, Deserialize, Debug)]
    #[allow(non_snake_case)]
    pub struct Http {
        pub path: String,
        pub protocol: String,
        pub method: String,
        pub sourceIp: String,
        pub userAgent: String,
    }

    #[derive(Serialize, Deserialize, Debug)]
    #[allow(non_snake_case)]
    pub struct RequestContext {
        pub accountId: String,
        pub timeEpoch: u64,
        pub routeKey: String,
        pub stage: String,
        pub domainPrefix: String,
        pub requestId: String,
        pub domainName: String,
        pub http: Http,
        pub time: String,
        pub apiId: String,
        pub authorizer: Option<BTreeMap<String, BTreeMap<String, String>>>,
    }

    #[derive(Serialize, Deserialize, Debug)]
    #[allow(non_snake_case)]
    pub struct LambdaProxyEvent {
        pub cookies: Option<Vec<String>>,
        pub headers: Option<BTreeMap<String, String>>,
        pub queryStringParameters: Option<BTreeMap<String, String>>,
        pub isBase64Encoded: bool,
        pub pathParameters: Option<BTreeMap<String, String>>,
        pub stageVariables: Option<BTreeMap<String, String>>,
        pub rawPath: String,
        pub requestContext: RequestContext,
        pub routeKey: String,
        pub body: Option<String>,
        pub rawQueryString: String,
        pub version: String,
    }


    #[derive(Serialize, Deserialize, Debug)]
    #[allow(non_snake_case)]
    pub struct LambdaResponse {
        pub statusCode: u16,
        pub isBase64Encoded: bool,
        pub headers: Option<BTreeMap<String, String>>,
        pub body: String,
    }

    impl Default for LambdaResponse {
        fn default() -> Self {
            LambdaResponse {
                statusCode: 200,
                isBase64Encoded: false,
                headers: None,
                body: "".to_string(),
            }
        }
    }
}