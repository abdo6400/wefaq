import { BadRequestException, ConflictException } from '@nestjs/common';
import { QuestionItem } from '../question-catalog/question-catalog.types';
import {
  parseCreateQuestionInput,
  parseListQuestionsQuery,
  parseUpdateQuestionInput,
} from './questions.validator';

describe('questions.validator', () => {
  const existingItem: QuestionItem = {
    id: 'comm-intro-1',
    text: 'نص أصلي',
    clarification: 'توضيح أصلي',
    topic: 'communication',
    depth: 'introductory',
    suitableModes: ['together', 'phone'],
    isDevelopmentOnly: false,
  };

  describe('parseCreateQuestionInput', () => {
    it('creates a valid question and defaults isDevelopmentOnly to true', () => {
      const created = parseCreateQuestionInput(
        {
          text: '  سؤال جديد للحوار  ',
          clarification: '  توضيح الهدف  ',
          topic: 'finances',
          depth: 'deeper',
          suitableModes: ['together'],
        },
        new Set(['comm-intro-1']),
      );

      expect(created.id).toMatch(/^custom-finan-deep-[0-9a-f]{6}$/);
      expect(created.text).toBe('سؤال جديد للحوار');
      expect(created.clarification).toBe('توضيح الهدف');
      expect(created.topic).toBe('finances');
      expect(created.depth).toBe('deeper');
      expect(created.suitableModes).toEqual(['together']);
      expect(created.isDevelopmentOnly).toBe(true);
    });

    it('rejects duplicate custom id with ConflictException', () => {
      expect(() =>
        parseCreateQuestionInput(
          {
            id: 'comm-intro-1',
            text: 'سؤال مكرر',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
          },
          new Set(['comm-intro-1']),
        ),
      ).toThrow(ConflictException);
    });

    it('rejects unsafe custom id or empty text', () => {
      expect(() =>
        parseCreateQuestionInput(
          {
            id: 'bad id!',
            text: 'سؤال',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
          },
          new Set(),
        ),
      ).toThrow(BadRequestException);

      expect(() =>
        parseCreateQuestionInput(
          {
            text: '   ',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
          },
          new Set(),
        ),
      ).toThrow(BadRequestException);
    });
  });

  describe('parseUpdateQuestionInput', () => {
    it('resets isDevelopmentOnly to true when content changes without explicit approval', () => {
      const updated = parseUpdateQuestionInput(
        { text: 'نص معدل' },
        existingItem,
      );

      expect(updated.text).toBe('نص معدل');
      expect(updated.isDevelopmentOnly).toBe(true);
    });

    it('clears clarification when blank string is passed and allows explicit approval flag', () => {
      const updated = parseUpdateQuestionInput(
        { clarification: '   ', isDevelopmentOnly: false },
        existingItem,
      );

      expect(updated).not.toHaveProperty('clarification');
      expect(updated.isDevelopmentOnly).toBe(false);
    });

    it('rejects changing id or empty update body', () => {
      expect(() =>
        parseUpdateQuestionInput({ id: 'other-id', text: 'x' }, existingItem),
      ).toThrow(BadRequestException);

      expect(() => parseUpdateQuestionInput({}, existingItem)).toThrow(
        BadRequestException,
      );
    });
  });

  describe('parseListQuestionsQuery', () => {
    it('parses filters and bounds pagination safely', () => {
      const query = parseListQuestionsQuery({
        topic: 'coreValues',
        depth: 'deeper',
        mode: 'phone',
        isDevelopmentOnly: 'true',
        search: '  الصدق ',
        page: '2',
        limit: '25',
      });

      expect(query).toEqual({
        topic: 'coreValues',
        depth: 'deeper',
        mode: 'phone',
        isDevelopmentOnly: true,
        search: 'الصدق',
        page: 2,
        limit: 25,
      });
    });

    it('rejects invalid enum or out-of-range limit', () => {
      expect(() =>
        parseListQuestionsQuery({ topic: 'invalidTopic' }),
      ).toThrow(BadRequestException);
      expect(() => parseListQuestionsQuery({ limit: '9999' })).toThrow(
        BadRequestException,
      );
    });
  });
});
