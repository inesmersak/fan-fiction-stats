from bs4 import BeautifulSoup
import datetime
import re


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
        :return: boolean
        """
        # The title has href attribute, but no rel attribute.
        return tag.has_attr('href') and not tag.has_attr('rel')

    story_data = dict()

    heading = story_html.find('h4', class_='heading')
    title = heading.find(find_title)
    story_data['title'] = title.text
    story_id = title['href'].split('/')
    story_data['story_id'] = story_id[-1]
    author = heading.find(rel=True)
    if author:
        author = author.text
        if '(' in author:
            author = author.split('(')
            author = author[len(author)-1]
            author = author[:len(author)-1]
        story_data['author'] = author
    else:
        story_data['author'] = 'Anonymous'

    fandoms = story_html.find('h5', class_='fandoms')
    story_data['fandoms'] = [fandom.text for fandom in fandoms.find_all('a')]

    required_tags = story_html.find('ul', class_='required-tags')
    story_data['warnings'] = [warning.text for warning in required_tags.find_all('span', class_='warnings')]
    story_data['categories'] = required_tags.find('span', class_='category').text.split(', ')
    story_data['rating'] = required_tags.find('span', class_='rating').text

    date = story_html.find('p', class_='datetime').text
    story_data['date_published'] = prepare_date(date)

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

    current_chapters, all_chapters = story_data['chapters'].split('/')
    if current_chapters == all_chapters:
        story_data['completed'] = True
    else:
        story_data['completed'] = False
    story_data['chapters'] = int(current_chapters)

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


def parse_user_data(username, user_profile_html):
    """
    Returns a dictionary containing user data.
    :param username: Username of the user whose data we want to get.
    :param user_profile_html: HTML code of the user's profile page.
    :return: user_data
    """
    profile = BeautifulSoup(user_profile_html, 'html.parser')
    user_data = dict()
    user_data['username'] = username

    meta = profile.find('dl', class_='meta')
    try:
        date_joined = meta.find('dt', text='I joined on:').next_sibling.next_sibling.text.split('-')
        date_joined = [int(d) for d in date_joined]
        user_data['date_joined'] = datetime.date(*date_joined)
    except AttributeError:
        print(username)

    try:
        birthday = meta.find('dd', class_='birthday').text
        if birthday:
            birthday = birthday.split('-')
            birthday = [int(d) for d in birthday]
            user_data['birthday'] = datetime.date(*birthday)
    except AttributeError:  # birthday div does not exist
        pass

    try:
        user_data['location'] = meta.find('dt', class_='location').next_sibling.next_sibling.text
    except AttributeError:  # location div does not exist
        pass

    return user_data
