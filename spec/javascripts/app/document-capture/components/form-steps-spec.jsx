import React from 'react';
import userEvent from '@testing-library/user-event';
import sinon from 'sinon';
import render from '../../../support/render';
import FormSteps from '../../../../../app/javascript/app/document-capture/components/form-steps';

describe('document-capture/components/form-steps', () => {
  const STEPS = [
    { name: 'first', component: () => <span>First</span> },
    {
      name: 'second',
      component: ({ value = '', onChange }) => (
        <>
          <span>Second</span>
          <input value={value} onChange={(event) => onChange(event.target.value)} />
        </>
      ),
    },
    { name: 'last', component: () => <span>Last</span> },
  ];

  it('renders nothing if given empty steps array', () => {
    const { container } = render(<FormSteps steps={[]} />);

    expect(container.childNodes).to.have.lengthOf(0);
  });

  it('renders the first step initially', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    expect(getByText('First')).to.be.ok();
  });

  it('renders continue button at first step', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    expect(getByText('Continue')).to.be.ok();
  });

  it('renders the active step', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));

    expect(getByText('Second')).to.be.ok();
  });

  it('renders continue button until at last step', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));

    expect(getByText('Continue')).to.be.ok();
  });

  it('renders submit button at last step', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));
    userEvent.click(getByText('Continue'));

    expect(getByText('Submit')).to.be.ok();
  });

  it('submits with form values', () => {
    const onComplete = sinon.spy();
    const { getByText, getByRole } = render(<FormSteps steps={STEPS} onComplete={onComplete} />);

    userEvent.click(getByText('Continue'));
    userEvent.type(getByRole('textbox'), 'val');
    userEvent.click(getByText('Continue'));
    userEvent.click(getByText('Submit'));

    expect(onComplete.getCall(0).args[0]).to.eql({
      second: 'val',
    });
  });

  it('pushes step to URL', () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));

    expect(window.location.search).to.equal('?step=second');
  });

  it('syncs step by history events', async () => {
    const { getByText, findByText, getByRole } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));
    userEvent.type(getByRole('textbox'), 'val');

    window.history.back();

    expect(await findByText('First')).to.be.ok();
    expect(window.location.search).to.equal('');

    window.history.forward();

    expect(await findByText('Second')).to.be.ok();
    expect(getByRole('textbox').value).to.equal('val');
    expect(window.location.search).to.equal('?step=second');
  });

  it('clear URL parameter after submission', (done) => {
    const onComplete = sinon.spy(() => {
      expect(window.location.search).to.equal('');

      done();
    });
    const { getByText } = render(<FormSteps steps={STEPS} onComplete={onComplete} />);

    userEvent.click(getByText('Continue'));
    userEvent.click(getByText('Continue'));
    userEvent.click(getByText('Submit'));
  });

  it('maintains focus after step change', async () => {
    const { getByText } = render(<FormSteps steps={STEPS} />);

    userEvent.click(getByText('Continue'));

    expect(document.activeElement).to.equal(getByText('Continue'));
  });
});
