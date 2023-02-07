#  -*- coding: utf-8 -*-

from ptools.logger import Logger

import logging
import time
from datetime import datetime

try:
    import boto3
except ImportError:
    pass


class CloudWatch(object):
    def __init__(self, log_group_name='/custom/logs', log_stream_name='', level=0, request_id=''):
        self.log_group_name = log_group_name
        ts = datetime.now().strftime("%s")
        if request_id:
            self.request_id = request_id
        else:
            self.request_id = ts
        if not log_stream_name:
            self.log_stream_name = datetime.now().strftime("%Y/%m/%S %H-%M-%S ") + ts
        else:
            self.log_stream_name = log_stream_name
        self.__kwargs = {}
        try:
            self.client = boto3.client('logs')
            self.client.create_log_stream(logGroupName=self.log_group_name, logStreamName=self.log_stream_name)
            if not level:
                self.level = Logger.getLevel()
            else:
                self.level = level
        except Exception as e:
            self.level = 0
            Logger.debug(e)

    def getLevel(self):
        return self.level

    def setLevel(self, level=0):
        try:
            self.level = int(level)
        except Exception as e:
            print(e)

    def put_log_events(self, text='', level='INFO'):
        ts = datetime.now().strftime("%Y-%m-%ST%H:%M:%S.%f")[:-3]+'Z'
        message = f'[{level}] {ts} {self.request_id} {text}'
        try:
            response = self.client.put_log_events(
                logGroupName=self.log_group_name,
                logStreamName=self.log_stream_name,
                logEvents=[
                    {
                        'timestamp': int(round(time.time() * 1000)),
                        'message': message
                    },
                ],
                **self.__kwargs
            )
            self.__kwargs['sequenceToken'] = response["nextSequenceToken"]
        except Exception as e:
            print(f'{text} -#- {e}')

    def debug(self, text):
        if logging.DEBUG >= self.level:
            self.put_log_events(text=text, level='DEBUG')

    def info(self, text):
        if logging.INFO >= self.level:
            self.put_log_events(text=text, level='INFO')

    def warning(self, text):
        if logging.WARNING >= self.level:
            self.put_log_events(text=text, level='WARNING')

    def error(self, text):
        if logging.ERROR >= self.level:
            self.put_log_events(text=text, level='ERROR')

    def critical(self, text):
        if logging.CRITICAL >= self.level:
            self.put_log_events(text=text, level='ERROR')
