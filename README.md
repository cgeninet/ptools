# ptools

## Requirements :
- git
- python3 and pip3
- Docker Desktop or docker.io
- curl
- aws cli

## Project structure :

```
MyProject  
├── main.py 
├── app  
│   ├── __init__.py  
│   ├── app.py  
│   └── ...       
├── ptools  
│   ├── Makefile
│   └── ...  
├── requirements.txt  
├── tests  
│   ├── requirements.txt  
│   ├── test_main.py    
│   └── ...
└── ...  
```

### main.py

```
#!/usr/bin/env python3
#  -*- coding: utf-8 -*-

def lambda_handler(event, context):
    return {'result': str(event)}
```

### test_main.py

```
#  -*- coding: utf-8 -*-

import unittest

import main


class MyTest(unittest.TestCase):
    def test_main(self):
        pass
```