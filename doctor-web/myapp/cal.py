import  requests


def getcalval(q):
    print("https://www.google.co.in/search?q=calories in "+q)

    res=requests.get("https://www.google.co.in/search?q=calories in "+q).text

    try:
        res1=res.split('<table class="LnMnt"')[1]

        res1=res1.split('<tr>')

        import re

        def remove_html_tags(text):
            clean = re.compile('<.*?>')
            return re.sub(clean, '', text)

        # html_text = "<p>This is <b>HTML</b> content.</p>"
        #
        # print(clean_text)

        for i in range(2,len(res1)-1):

            clean_text = remove_html_tags(res1[i])
            print(clean_text)
            if 'Calories ' in clean_text:
                return clean_text.replace('Calories ',"")
    except:
        res1=res.split('<span class="FCUp0c rQMQod">')[1].split("k")[0].split(' ')[0]
        return res1

# print(getcalval("100 gm chicken fry"))