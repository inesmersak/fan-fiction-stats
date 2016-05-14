import threading
import math
from database import Database
from config_database import *
import get_data
import parse_data
import time
import datetime


def fill_database_in_range(start, end, address, db, thread_id):
    pages = get_data.get_pages(start, end, address)
    p = 1
    for page in pages:
        page_data = parse_data.parse_stories_from_page(page)
        s = 1
        for story in page_data:
            if not db.author_exists(story):
                author = parse_data.parse_user_data(story['author'], get_data.get_user_data(story['author']))
                db.insert_author(author)
            if not db.story_exists(story):
                db.insert_story(story)
            # with open('data/id' + str(thread_id) + '-p' + str(p) + '-s' + str(s) + '.out',
            # 'w', encoding='utf8') as inp:
            #     for k, v in story.items():
            #         print('{0}: {1}'.format(k, v), file=inp)
            s += 1
        p += 1


def create_and_fill_database():
    t0 = time.time()
    db = Database(host, db_name, user, password)
    if db.connect():
        db.create_tables()
        address = 'http://archiveofourown.org/tags/Harry%20Potter%20-%20J*d*%20K*d*%20Rowling/works?'

        number_of_pages = get_data.get_number_of_pages(address)
        start_number = number_of_pages - 20
        number_of_threads = 50
        pages_per_thread = int(math.ceil(number_of_pages/number_of_threads))

        th = []
        for i in range(start_number, number_of_pages + 1, pages_per_thread):
            th.append(threading.Thread(target=fill_database_in_range,
                                       args=(i, min(i + pages_per_thread - 1, number_of_pages), address, db,
                                             i // pages_per_thread)))

        for thread in th:
            thread.start()
        for thread in th:
            thread.join()

        db.disconnect()
    tk = time.time()
    print(datetime.timedelta(seconds=tk-t0))

if __name__ == "__main__":
    create_and_fill_database()
    # print(parse_data.parse_user_data(get_data.get_user_data('inspiritedmama')))
