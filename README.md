from https://www.cloudops.com/2020/01/remote-sensing-data-pipelines-kubernetes-and-neural-networks-in-ecology/

The model is now much more efficient than what was described in the blog post, taking <5 epochs to converge instead of many more. This was accomplished through residual learing, with inspiration from https://arxiv.org/abs/1708.00838v1. I am looking to implement a UNet(https://arxiv.org/abs/1505.04597) inspired model which may be better at feature recognition and which builds upon the advances found using residual training. Happy coding!
