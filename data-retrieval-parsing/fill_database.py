import re
import threading
import requests
from database import Database
from config_database import *
import get_data
import parse_data


def fill_database_in_range(start, end, address, db):
    pages = get_data.get_pages(start, end, address)
    for page in pages:
        page_data = parse_data.parse_stories_from_page(page)
        for story in page_data:
            db.insert_story(story)


def main():
    db = Database(host, db_name, user, password)
    if db.connect():
        db.create()
        address = 'http://archiveofourown.org/tags/Harry%20Potter%20-%20J*d*%20K*d*%20Rowling/works?'

        number_of_pages = get_data.get_number_of_pages(address)
        start_number = 1
        pages_per_thread = 10

        th = []
        for i in range(start_number, number_of_pages+1, pages_per_thread):
            th.append(threading.Thread(target=fill_database_in_range,
                                       args=(i, min(i+pages_per_thread, number_of_pages), address, db)))

        for thread in th:
            thread.start()
        for thread in th:
            thread.join()

        db.disconnect()

if __name__ == "__main__":
    main()
