#  -*- coding: utf-8 -*-

import inspect
import logging
from os.path import dirname

logging.basicConfig(format='%(asctime)s:%(levelname)s:%(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("main")
logger.setLevel(logging.CRITICAL)


class Logger(object):
    DEBUG = logging.DEBUG
    INFO = logging.INFO
    WARNING = logging.WARNING
    ERROR = logging.ERROR
    CRITICAL = logging.CRITICAL
    path_len = 0

    @staticmethod
    def getLevel():
        return logger.level

    @staticmethod
    def setLevel(level):
        logger.setLevel(int(level))

    @staticmethod
    def log(text):
        frame = inspect.currentframe().f_back.f_back
        path = frame.f_globals['__name__']
        if path == '__main__':
            if Logger.path_len == 0:
                Logger.path_len = len(dirname(dirname(__file__))) + 1
            path = dirname(inspect.getmodule(frame).__file__[Logger.path_len:]).replace('/', '.')
        line = frame.f_lineno
        del frame
        line = '{}:{}: {}'.format(path, str(line).rjust(4, '0'), text)
        return line

    @staticmethod
    def debug(text):
        logger.debug(Logger.log(text))

    @staticmethod
    def info(text):
        logger.info(Logger.log(text))

    @staticmethod
    def warning(text):
        logger.warning(Logger.log(text))

    @staticmethod
    def error(text):
        logger.error(Logger.log(text))

    @staticmethod
    def critical(text):
        logger.error(Logger.log(text))
        exit(-1)


Logger.setLevel(Logger.CRITICAL)
