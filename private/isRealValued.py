import torch
import numpy as np

def isRealValued(X):
    """  
    isRealValued:
      Checks whether X is real-valued, that is, it either has no
      imaginary part or it's imaginary part is exactly zero.  

      Note that MATLAB's isreal function only checks whether there is an
      imaginary part allocated, i.e., isreal returns false if an
      imaginary part is allocated, even if it is zero.
    """

    if torch.is_tensor(X):
      tf = torch.all(torch.isreal(X) == True).item()  
    else:
      tf = np.isreal(X)

    return tf