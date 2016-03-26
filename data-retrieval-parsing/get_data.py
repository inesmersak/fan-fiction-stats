import requests
import re
import threading
import os


def get_pages(start, end, address):
    """
    Downloads the content from pages {start]-{end} and writes the content of the n-th page to 'pages/n.html'.
    :param start: First page to get.
    :param end: Last page to get.
    :param address: The address from which to get the content.
    :return: None
    """
    for page in range(start, end+1):
        parameters = {
            'page': page,
        }

        r2 = requests.get(address, params=parameters)
        with open('pages/{0}.html'.format(page), 'w', encoding='utf8') as output:
            output.write(r2.text)

    return


def get_all_pages():
    """
    Gets all of the pages with results using threading.
    :return:
    """
    directory = './pages'
    if not os.path.exists(directory):  # makes subdirectory pages, if it doesn't exist
        os.makedirs(directory)

    address = 'http://archiveofourown.org/tags/Harry%20Potter%20-%20J*d*%20K*d*%20Rowling/works?'

    r = requests.get(address)
    pages_pattern = re.compile(r'<li><a href=".*?">(\d*?)</a></li> <li class="next" title="next">')
    number_of_pages = int(pages_pattern.search(r.text).group(1))
    start_number = 4300
    step = 10

    for i in range(start_number, number_of_pages+1, step):
        th = threading.Thread(target=get_pages, args=(i, min(i+step, number_of_pages), address))
        th.start()

get_all_pages()
