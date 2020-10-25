using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon.Lambda.Core;
using Amazon.Lambda.TestUtilities;
using ZeroTube.Lambda.PopulateYouTubeLinksFunction;
using NUnit.Framework;

namespace ZeroTube.Lambda.PopulateYouTubeLinksFunction.Tests
{
    public class FunctionTest
    {
        [Test]
        public void TestToUpperFunction()
        {
            // Invoke the lambda function and confirm the string was upper cased.
            var function = new Function();
            var context = new TestLambdaContext();
            //var upperCase = function.FunctionHandler(context);
        }
    }
}
