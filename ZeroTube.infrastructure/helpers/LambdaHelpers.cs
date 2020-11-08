using System;

namespace ZeroTube.infrastructure.helpers
{
    public static class LambdaHelpers
    {
        public static string GetEnvVar(string envVarName)
        {
            var envVariable = Environment.GetEnvironmentVariable(envVarName);

            if (string.IsNullOrEmpty(envVariable)) throw new Exception($"Environmental variable '{envVarName}' not found/has no value");

            return envVariable;
        }
    }
}
