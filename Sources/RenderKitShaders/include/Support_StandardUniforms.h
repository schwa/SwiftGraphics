struct ModelTransformsNEW {
//    float4x4 modelMatrix
    float4x4 modelViewMatrix; // model space -> camera space // TODO: 4x3
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
};

struct ModelUniformsNEW {
    float4x4 modelMatrix;
    float4x4 modelViewMatrix; // model space -> camera space
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
    float4x4 modelViewProjectionMatrix;
};

struct CameraUniformsNEW {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};
