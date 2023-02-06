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
    logger = None

    @classmethod
    def set(cls, logger_instance=None):
        try:
            if logger_instance is not None and logger_instance.level:
                cls.logger = logger_instance
                return
        except Exception:
            pass
        cls.logger = logging.getLogger("main")

    @staticmethod
    def getLevel():
        return logger.level

    @staticmethod
    def setLevel(level):
        logger.setLevel(int(level))

    @staticmethod
    def log(text):
        if Logger.logger is None:
            Logger.set()
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
        message = Logger.log(text)
        Logger.logger.debug(message)

    @staticmethod
    def info(text):
        message = Logger.log(text)
        Logger.logger.info(message)

    @staticmethod
    def warning(text):
        message = Logger.log(text)
        Logger.logger.warning(message)

    @staticmethod
    def error(text):
        message = Logger.log(text)
        Logger.logger.error(message)

    @staticmethod
    def critical(text):
        message = Logger.log(text)
        Logger.logger.error(message)
        exit(-1)


Logger.setLevel(Logger.CRITICAL)
