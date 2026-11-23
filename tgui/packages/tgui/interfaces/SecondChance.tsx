import { Button, NoticeBox, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  status: string;
  name: string | null;
  registered: boolean;
  sampled: boolean;
  printing: boolean;
  remaining: number;
  owner: boolean;
  operational: boolean;
};
export const SecondChance = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Window width={430} height={330}>
      <Window.Content>
        <Section title="Second Chance Genetic Insurance">
          <NoticeBox>{data.status}</NoticeBox>
          <p>
            Swipe your personal ID on the pod, then provide a DNA sample below.
            One enrollment covers one reconstruction.
          </p>
          <p>
            Upon death: 50 credits from your registered account, five seconds to
            print, your ID and a grey jumpsuit.
          </p>
          {data.name && <p>Stored subject: {data.name}</p>}
          {data.printing && (
            <p>Printing: {Math.ceil(data.remaining)} seconds remaining.</p>
          )}
          <Stack>
            <Stack.Item>
              <Button
                icon="dna"
                disabled={!data.owner || !data.operational || data.registered}
                onClick={() => act('sample')}
              >
                Take DNA Sample
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="shield-heart"
                disabled={
                  !data.owner ||
                  !data.operational ||
                  !data.sampled ||
                  data.registered
                }
                onClick={() => act('register')}
              >
                Register Second Life
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
