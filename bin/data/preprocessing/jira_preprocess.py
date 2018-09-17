import collections
import typing

import re
import textacy

# Options
USE_SPECIAL_TOKEN = True

TBL_REPLACE_STR = 0
TBL_REGEX_PATTERN = 1

# List of special replacement tokens
SPECIAL_TOKENS = {
    'code_comment':           ['XXXCodeCommentXXX',             re.compile(r'(\/\*([^\*]|(\*+([^\*\/])))*\*+\/)', re.MULTILINE)],
    'code_function' :         ['XXXFunctionXXX',                re.compile(r'(([A-Za-z\_]+[0-9A-Za-z\_]\.)+([0-9A-Za-z\_]+)\s*\([^\)]*\)(\s*\;)?)')],
    'code_source':            ['XXXCodeSourceXXX',              None],
    'code_source_trycatch':   ['XXXCodeSourceTryCatchXXX',      None],#re.compile(r'((try\s*\{([^\}]|[\r\n])*\})((\s*catch\s*.*\{([^\}]|[\r\n])*\})+(\s*finally\s*.*\{([^\}]|[\r\n])*\})?)+)', re.MULTILINE)],
    'code_sql_line':          ['XXXCodeSQLLineXXX',             re.compile(r'.*\;\s*$')],
    'email_address':          ['XXXEmailAddressXXX',            None],
    'git_at' :                ['XXXGitAtXXX',                   re.compile(r'\@\@.*\@\@')],
    'git_commit' :            ['XXXGitCommitXXX',               re.compile(r'(^(([\-AMD]\s{2,}).*\n(.*\n)?)?([\+AMD]\s{2,}).*)|(^(([\-AMD]{2,3}\s{1,}).*\n(.*\n)?)?([\+AMD\!]{2,3}\s{1,}).*)', re.MULTILINE)],
    'issue_id':               ['XXXIssueIdXXX',                 re.compile(r'(\b[A-Z]+-\d+\b)')],
    'inline_quote':           ['XXXInlineQuoteXXX',             re.compile(r'^>.+?$', re.MULTILINE)],
    'java_code':              ['XXXJavaCodeXXX',                None],
    'jira_attachment_link':   ['XXXJiraAttachmentXXX',          re.compile(r'\[\^.*\]')],
    'jira_block_quote':       ['XXXJiraBlockQuoteXXX',          re.compile(r'^bq\..*$', re.MULTILINE)],
    'jira_code_block':        ['XXXJiraCodeBlockXXX',           re.compile(r'{code([\S\s]*?){code}')],
    'jira_noformat_block':    ['XXXJiraNoFormatBlockXXX',       re.compile(r'{noformat}([\S\s]*?){noformat}')],
    'jira_quote_block':       ['XXXJiraQuoteBlockXXX',          re.compile(r'{quote}(?:[\S\s]*?){quote}')],
    'jira_user_link':         ['XXXJiraUserLinkXXX',            re.compile(r'\[~[.\w]+\]')],
    'quotes_block':           ['XXXQuotesBlockXXX',             re.compile(r'\"(\w+(\s\w+)*)\"')],
    'relative_windows_path':  ['XXXRelativeWindowsFilePathXXX', re.compile(r'(\\[\w^ ]+)+\\?(\.\w+)?')],
    'revision_number':        ['XXXRevisionNumberXXX',          re.compile(r'((revision)|(rev))\s*\d+')],
    'special_char':           ['XXXSpecialCharXXX',             re.compile(r'(\*)+|(\#)+|(\-)+')],
    'stack_trace_entry':      ['XXXStackTraceEntryXXX',         re.compile(r'([\w$<>]+\.)*[\w<>]+' + r'\((([\w<>]+\.java:\d+)|[uU]nknown [sS]ource|[nN]ative [mM]ethod)\)')],
    'stack_trace':            ['XXXStackTraceXXX',              re.compile(r'(:?(:?at)?.+XXXStackTraceEntryXXX[\r\n\t ]*)+')],
    'url':                    ['XXXUrlXXX',                     None],
    'unix_path':              ['XXXUnixFilePathXXX',            re.compile(r'(\/[\w^ ]+)+\/?(\.\w+)?')],
    'version_number':         ['XXXVersionNumberXXX',           re.compile(r'\d+\.\d+\.\d+(.[\w\d]+)?')],
    'windows_path':           ['XXXWindowsFilePathXXX',         re.compile(r'(?:[a-zA-Z]\:\|\\\\[\w\.]+\\[\w.$]+)\\(?:[\w]+\\)*\w([\w.])+')],
    'xml_block':              ['XXXXmlBlockXXX',                re.compile(r'XXXXmlTagXXX[\s\w\d\.]*XXXXmlTagXXX')],
    'xml_tag':                ['XXXXmlTagXXX',                  re.compile(r'</?[\s\w.:\-=\" ]+?/?>')]
}

SPECIAL_TOKENS_VALUE_LOWER = [v[TBL_REPLACE_STR].lower() for v in SPECIAL_TOKENS.values()]


def is_special_token(token: str) -> bool:
    """Check if token represents a special replacement

    >>> is_special_token('XXXUrlXXX')
    True
    >>> is_special_token('  xxxunixfilepathxxx  ')
    True
    >>> is_special_token('  helloworld  ')
    False

    :param token:
    :return: true, if special
    """
    trimmed = token.strip()

    return (trimmed.lower() in SPECIAL_TOKENS_VALUE_LOWER)


def pad_str(token: str, use_special_token=USE_SPECIAL_TOKEN) -> str:
    if use_special_token:
        return ' ' + SPECIAL_TOKENS[token][TBL_REPLACE_STR] + ' '
    else:
        return ' '


def replace(text: str, token: str, replace_prefix='', replace_postfix='', use_special_token=USE_SPECIAL_TOKEN) -> str:    
    return SPECIAL_TOKENS[token][TBL_REGEX_PATTERN].sub(replace_prefix + 
                                                        pad_str(token, use_special_token) + 
                                                        replace_postfix, 
                                                        text)


REPLACE_WORDS_TBL = {
    "repo" : "repository",
    
}
def replace_word_by_word(text: str) -> str:
    if text in REPLACE_WORDS_TBL:
        return REPLACE_WORDS_TBL[text]
    else:
        return text



    
# TODO: Version control status
#
# Example:
#
# Touches the following files:
#
# --------------
#
# M java/engine/org/apache/derby/impl/jdbc/EmbedResultSet.java
# M java/engine/org/apache/derby/impl/jdbc/EmbedStatement.java
#
# Changes to the embedded physical statement.
# --------------
#
# Status markers:
# * SVN: http://svnbook.red-bean.com/en/1.7/svn.ref.svn.c.status.html
# * GIT: https://git-scm.com/docs/git-status
#
# Regular expression: re.compile(r'^[ACDMRUX] .*?$', re.MULTILINE)
#


def split_text_to_paragraphs(text: str) -> list:
    """Split text into paragraphs

    A paragraphs is detected by an empty line

    :param text: input text
    :return: list of paragraphs
    """
    paragraphs = []
    current_paragraph = []
    for line in text.splitlines():
        # non empty line -> add to paragraph
        if len(line.strip()) > 0:
            current_paragraph.append(line)
        else:
            # empty line -> end of paragraph
            if len(current_paragraph) > 0:
                paragraphs.append('\n'.join(current_paragraph))
                current_paragraph = []

    if len(current_paragraph) > 0:
        paragraphs.append('\n'.join(current_paragraph))

    return paragraphs


def is_camel_case(token: str) -> bool:
    if len(token) <= 2:
        return False

    first_to_lower = token[0].lower() + token[1:]
    return (first_to_lower != first_to_lower.lower()) and (first_to_lower != first_to_lower.upper())


# https://docs.oracle.com/javase/tutorial/java/nutsandbolts/_keywords.html
JAVA_KEYWORDS = [
    'abstract', 'assert',
    'boolean', 'break', 'byte',
    'case', 'catch', 'char', 'class', 'continue',
    'default', 'do', 'double',
    'else', 'enum', 'extends',
    'final', 'finally', 'float', 'for'
    'if', 'implements', 'import', 'instanceof', 'int', 'interface',
    'long', 'native', 'new',
    'package', 'private', 'protected', 'public',
    'return',
    'short', 'static', 'strictfp', 'super', 'switch', 'synchronized',
    'this', 'throw', 'throws', 'transient', 'try',
    'void', 'volatile',
    'while'
]


def _get_text_statistics(text: str, nlp_object) -> typing.Tuple:
    """Get text statistics useful for source code detection

    :param text: text
    :param nlp_object: spacy nlp object
    :return:
    """

    def is_bracket(c: str) -> bool:
        return c in '<>(){}[]'

    stats = collections.Counter()

    stats['raw_bracket'] = len(list(filter(is_bracket, text)))

    parsed_text = nlp_object(text)

    for token in parsed_text:
        stats['token'] += 1

        if token.text == ';':
            stats['semicolon'] += 1
        elif token.text in JAVA_KEYWORDS:
            stats['java_keyword'] += 1
        elif is_camel_case(token.text):
            stats['camel_case'] += 1
        elif token.is_digit:
            stats['digit'] += 1
        elif token.is_bracket:
            stats['bracket'] += 1
        elif token.pos_ == 'SYM':
            stats['symbol'] += 1
        elif token.is_punct:
            stats['punct'] += 1

    return stats, parsed_text


def _is_java_source_code(statistics: dict) -> bool:
    non_words = statistics['raw_bracket'] + statistics['symbol'] + statistics['semicolon'] + statistics['digit']
    non_word_ratio = float(non_words) / float(statistics['token'])

    java_like = (statistics['java_keyword'] > 3) or (statistics['camel_case'] > 3)

    return non_word_ratio > 0.20 and java_like


def clean_text_from_jira(raw_text: str, nlp_object, use_special_token: bool) -> str:
    """Clean up text (description, comment message, ...) from JIRA issue tracking system

    Replace non natural language constructs (technical noise with special tokens)

    :param raw_text: text to clean
    :param nlp_object: spaCy NLP object (used for tokenization)
    :return: cleaned up text
    """
    
    text = replace(raw_text, 'jira_code_block', use_special_token=use_special_token)
    """Replace code blocks

    https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=advanced
    """
    
    text = replace(text, 'jira_noformat_block', use_special_token=use_special_token)
    """Replace preformated text

    https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=advanced
    """
    
    text = replace(text, 'jira_quote_block', use_special_token=use_special_token)
    """Replace quote blocks

    https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=texteffects

    >>> message = '''bq. I still see version ranges including SNAPSHOT versions
    ... Some text
    ... bq. compile -> compile = runtime
    ... bq. This would make many builds far more robust to changes in child dependencies.'''
    >>> replace_jira_block_quotes(message)
    ' XXXJiraBlockQuoteXXX \\nSome text\\n XXXJiraBlockQuoteXXX \\n XXXJiraBlockQuoteXXX '
    """

    text = replace(text, 'inline_quote', use_special_token=use_special_token)
    """Replace inline quotes introduced with >

    Example:
        > This is a inline quote, because it starts with '>'

    >>> message = '''John Doe wrote:
    ... > some quote
    ... normal other text'''
    >>> replace_inline_quotes(message)
    'John Doe wrote:\\n XXXInlineQuoteXXX \\nnormal other text'
    """

    text = replace(text, 'jira_block_quote', use_special_token=use_special_token)
    text = replace(text, 'stack_trace_entry', use_special_token=use_special_token)
    """Replace lines that match a stacktrace entry

    >>> replace_stack_trace_entries('at org.apache.derbyTesting.junit.BaseTestCase.runBare(BaseTestCase.java:113)')
    'at  XXXStackTraceEntryXXX '

    >>> replace_stack_trace_entries('at junit.extensions.TestSetup$1.protect(TestSetup.java:21)')
    'at  XXXStackTraceEntryXXX '

    >>> replace_stack_trace_entries('at org.apache.derby.impl.jdbc.EmbedConnection30.<init>(EmbedConnection30.java:73)')
    'at  XXXStackTraceEntryXXX '

    """
    
    text = replace(text, 'stack_trace', use_special_token=use_special_token)
    
    text = replace(text, 'xml_tag', use_special_token=use_special_token)
    """Replace xml tags

    >>> replace_xml_tags('<html>more</html>')
    ' XXXXmlTagXXX more XXXXmlTagXXX '

    >>> replace_xml_tags('<html attr=\"foo\" attr2=\"foo123\" attr-3 = \"value\">more</html>')
    ' XXXXmlTagXXX more XXXXmlTagXXX '

    >>> replace_xml_tags('<kie:consoleLogger />')
    ' XXXXmlTagXXX '

    >>> text = '''<kie:kbase includes="rules1Package" packages="au.org.nps.dsaas.rules" >'''
    >>> replace_xml_tags(text)
    ' XXXXmlTagXXX '

    :param text:
    :param replace_with:
    :return:
    """
    
    text = replace(text, 'xml_block', use_special_token=use_special_token)
    
    # from apritzkau
    text = replace(text, 'git_commit', use_special_token=use_special_token)
    #text = replace(text, '')
    text = replace(text, 'code_comment', use_special_token=use_special_token)
    #text = replace(text, 'code_source_trycatch', use_special_token=use_special_token)
    #text = replace(text, 'code_source')
    
    text = replace(text, 'code_function', use_special_token=use_special_token)
    """Replace functions

    cstmt.setObject(1,sMaxBooleanVal,java.sql.Types.BIT);
    ' XXXFunctionXXX '
    
    cstmt.setObject(1,sMaxBooleanVal,java.sql.Types.BIT)wasd
    ' XXXFunctionXXX wasd'
    
    wasd cstmt.setObject(1,sMaxBooleanVal,java.sql.Types.BIT) ; wasd wasd
    'wasd XXXFunctionXXX  wasd wasd'
    
    wasdwasd wasd cstmt.setObject(1,sMaxBooleanVal,java.sql.Types.BIT)wasd wasd
    'wasdwasd wasd  XXXFunctionXXX wasd wasd

    cstmt.setObject(1,sMaxBooleanVal,);
    ' XXXFunctionXXX '
    
    xsw.tmt.setObject(1,sMaxBooleanVal);
    ' XXXFunctionXXX '
    
    cstmt.setObject(1);
    ' XXXFunctionXXX '
    
    cstmt.setObject();
    ' XXXFunctionXXX '
    
    cstmt.setObject( );
    ' XXXFunctionXXX '
    
    Wstmt.setObject ();
    ' XXXFunctionXXX '
    
    Wstmt.setObject.etObject();
    ' XXXFunctionXXX '
    
    Wstmt.setObject.etObject (); wasd.
    ' XXXFunctionXXX  wasd.'
    
    Wstmt.s.etObject  () ;
    ' XXXFunctionXXX '
    
    Wstmt..etObject  () ;
    ' Wstmt..etObject  () ; '
    
    :param text:
    :param replace_with:
    :return:
    """
    
    
    text = replace(text, 'quotes_block', use_special_token=use_special_token)

   
    text = replace(text, 'revision_number', "revision", use_special_token=use_special_token)

    #text = replace_word_by_word(text)
    
    paragraphs = split_text_to_paragraphs(text)

    result = []

    for paragraph in paragraphs:
        stats, parsed_tokens = _get_text_statistics(paragraph, nlp_object)
        if _is_java_source_code(stats):
            result.append(pad_str('java_code', use_special_token=use_special_token))
        else:
            para_text = replace(paragraph, 'issue_id', use_special_token=use_special_token)
            para_text = replace(para_text, 'version_number', use_special_token=use_special_token)
            """
            >>> replace_version_numbers('have the issue with 6.0.0.Beta5 or 6.0.0.CR1 (which is about to go out)?')
            'have the issue with  XXXVersionNumberXXX  or  XXXVersionNumberXXX  (which is about to go out)?'

            >>> replace_version_numbers('Could you please try master (5.5.1-SNAPSHOT) ?')
            'Could you please try master ( XXXVersionNumberXXX ) ?'
            """

            para_text = replace(para_text, 'jira_attachment_link', use_special_token=use_special_token)
            para_text = replace(para_text, 'jira_user_link', use_special_token=use_special_token)
            """Replace user name references
            https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=links

            >>> replace_jira_user_links('[~micha]')
            ' XXXJiraUserLinkXXX '

            >>> replace_jira_user_links('[~micha123]')
            ' XXXJiraUserLinkXXX '

            >>> replace_jira_user_links('[~john.doe]')
            ' XXXJiraUserLinkXXX '

            >>> replace_jira_user_links('The text [~john.doe] more [~user2].')
            'The text  XXXJiraUserLinkXXX  more  XXXJiraUserLinkXXX .'
            """
            
            para_text = textacy.preprocess.replace_urls(para_text, pad_str('url', use_special_token=use_special_token))
            para_text = textacy.preprocess.replace_emails(para_text, pad_str('email_address', use_special_token=use_special_token))

            para_text = replace(para_text,'unix_path', use_special_token=use_special_token)
            para_text = replace(para_text, 'windows_path', use_special_token=use_special_token)
            para_text = replace(para_text, 'relative_windows_path', use_special_token=use_special_token)

            para_text = textacy.preprocess.unpack_contractions(para_text)

            result.append(para_text)

    return '\n\n'.join(result)


########################################################################################################################


def test_jira_block_quotes():
    jira_block_quotes = """bq. I still see version ranges including SNAPSHOT versions
Some text
bq. compile -> compile = runtime
bq. This would make many builds far more robust to changes in child dependencies.
"""
    print(replace(jira_block_quotes, 'jira_quote_block'))


def test_inline_quotes():
    inline_quotes = """
Daniel John Debrunner (JIRA) wrote:

> Seems like the permission class for "createDatabase" should be DatabasePermission, I could see this in the future being expanded to have additional actions of "shutdown", "drop", "encrypt" etc. Then of course the "createDatabase" action could be "create".
> more

Normal text

> other
    """

    print(replace(inline_quotes, 'inline_quotes'))


def test_main():
    test_jira_block_quotes()
    test_inline_quotes()


if __name__ == '__main__':
    test_main()
