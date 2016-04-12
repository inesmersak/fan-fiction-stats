from bs4 import BeautifulSoup
import datetime
import re
import os
import math
import threading


def prepare_date(date_string):
    """
    Transforms a string containing date to return a python date object.
    :param date_string: String, containing date in the form '28 Mar 2016'.
    :return: date_obj
    """
    months = {'Jan': 1,
              'Feb': 2,
              'Mar': 3,
              'Apr': 4,
              'May': 5,
              'Jun': 6,
              'Jul': 7,
              'Aug': 8,
              'Sep': 9,
              'Oct': 10,
              'Nov': 11,
              'Dec': 12}
    date = date_string.split()[::-1]
    date[1] = months[date[1]]
    date = [int(d) for d in date]
    date_obj = datetime.date(*date)
    return date_obj


def parse_story_data(story_html, debug=False):
    """
    Returns a dictionary with the story's properties (such as title, author, summary, characters,...).
    :param story_html: HTML code of the story.
    :param debug:
    :return: story_data
    """
    def find_title(tag):
        """
        This function is passed to BeautifulSoup parser in order to find title of the story.
        :param tag:
        :return:
        """
        # The title has href attribute, but no rel attribute.
        return tag.has_attr('href') and not tag.has_attr('rel')

    story_data = dict()

    heading = story_html.find('h4', class_='heading')
    story_data['title'] = heading.find(find_title).text
    author = heading.find(rel=True)
    if author:
        story_data['author'] = author.text
        story_data['author_profile'] = author.get('href')
    else:
        story_data['author'] = 'Anonymous'

    fandoms = story_html.find('h5', class_='fandoms')
    story_data['fandoms'] = [fandom.text for fandom in fandoms.find_all('a')]

    required_tags = story_html.find('ul', class_='required-tags')
    story_data['required_tags'] = [tag.text for tag in required_tags.find_all('li')]

    date = story_html.find('p', class_='datetime').text
    story_data['date'] = prepare_date(date)

    # TAGS
    tags = story_html.find('ul', class_='tags')
    story_data['warnings'] = [warning.text for warning in tags.find_all('li', class_='warnings')]
    relationships = [relationship.text for relationship in tags.find_all('li', class_='relationships')]
    story_data['relationships'] = relationships
    story_data['characters'] = [char.text for char in tags.find_all('li', class_='characters')]

    summary = story_html.find('blockquote', class_='summary')
    if summary:
        story_data['summary'] = summary.text.strip()

    # STATISTICS
    stats = story_html.find('dl', class_='stats')
    dt = stats.find_all('dt')
    dd = stats.find_all('dd')
    for i in range(len(dt)):
        class_name = dt[i].get('class')[0]
        class_name = class_name.replace('-', '_')
        if class_name == dd[i].get('class')[0]:
            dd_text = dd[i].text
            find_number = re.compile(r'(\d*,?\d*,?\d+)')  # finds numbers up to 999,999,999
            number = find_number.findall(dd_text)
            if len(number) == 1 and len(number[0]) == len(dd_text):  # the string in dd_text is actually an integer
                number = number[0]
                number = number.replace(',', '')
                number = int(number)
                story_data[class_name] = number
            else:
                story_data[class_name] = dd_text

    if debug:
        print(story_data)

    return story_data


def parse_stories_from_page(page_markup, debug=False):
    """
    Returns all of the stories on the page as an array of dictionaries.
    :param page_markup: HTML code of the page with stories.
    :param debug:
    :return: page_data
    """
    page = BeautifulSoup(page_markup, 'html.parser')
    stories = page.find_all('li', class_='work blurb group')

    page_data = []  # contains data for every story on the page
    for story in stories:
        page_data.append(parse_story_data(story))

    if debug:
        # prints the number of stories on the page and all the stories data
        print(len(stories))
        for story in page_data:
            print(story)

    return page_data


def parse_stories_in_range(directory, start, end, thread, result):
    """
    Parses the stories from pages {start}-{end} and returns an array of dictionaries, one dict for each story,
    for all the stories these pages contain.
    :param directory: The directory containing the pages to parse.
    :param start: First page to parse.
    :param end: Last page to parse.
    :param thread: Thread number.
    :param result: Array, containing results from n-th thread at result[n].
    """
    stories_range = []
    for i in range(start, end+1):
        # we assume file name 'n.html' for n-th page
        filename = os.path.join(directory, '{0}.html'.format(i))
        file_markup = open(filename, encoding='utf8')
        stories_range += parse_stories_from_page(file_markup)
    result[thread] = stories_range


def parse_all_stories(directory, files_per_thread=10, start_number=1, debug=False):
    """
    Returns all of the stories using threading.
    :param directory: The directory containing the pages to parse.
    :param files_per_thread: The number of files one thread will parse.
    :param start_number: First file to parse.
    :param debug:
    :return: all_stories
    """
    number_of_files = len([name for name in os.listdir(directory) if os.path.isfile(os.path.join(directory, name))])
    all_stories = [[] for _ in range(int(math.ceil(number_of_files/files_per_thread)))]

    th = []
    for i in range(start_number, number_of_files+1, files_per_thread):
        thread_id = int(math.ceil((i - start_number) / files_per_thread))
        th.append(
            threading.Thread(
                target=parse_stories_in_range,
                args=(directory, i, min(i+files_per_thread, number_of_files), thread_id, all_stories)
                )
        )

    for thread in th:
        thread.start()
    for thread in th:
        thread.join()

    if debug:
        with open('result', 'w', encoding='utf8') as output:
            for story_range in all_stories:
                print(story_range, file=output)

    return all_stories


def parse_user_data(user_profile_html):
    # TODO implement
    pass

if __name__ == '__main__':
    parse_all_stories('./pages', debug=True)
