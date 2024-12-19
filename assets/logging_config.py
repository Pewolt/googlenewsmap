# logging_config.py

import logging

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,  # Setzen Sie dies auf INFO oder WARNING in der Produktion
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler()
        ]
    )
